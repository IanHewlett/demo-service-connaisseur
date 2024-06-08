require 'json'

control "connaisseur" do
  title "connaisseur"
  tag "spec"

  app_name = "connaisseur"
  namespace = "connaisseur"
  chart_repo = "connaisseur"
  chart_name = "connaisseur"
  # chart_version = env_vars['connaisseur']['chart_version']
  deployment_name = "connaisseur-deployment"
  replicas = 3
  node_group = input('management_node_group_name')
  toleration_value = input('management_node_group_role')

  describe 'flux helmrelease' do
    let(:ready_condition) { JSON.parse(`kubectl get helmrelease #{app_name} -n #{namespace} -o jsonpath="{.status.conditions[?(@.type=='Ready')]}"`) }

    it "is in a ready state" do
      expect(ready_condition.dig('status')).to eq("True")
    end
  end

  describe 'deployment' do
    before { `kubectl rollout status deployment #{deployment_name} -n #{namespace} --timeout=1m` }
    let(:resource) { JSON.parse(`kubectl get deployment #{deployment_name} -n #{namespace} -o json`) }
    let(:github_secret) { resource.dig('spec', 'template', 'spec', 'volumes').find { |volume| volume['name'] == 'cosign-vol' } }

    it "has expected replicas" do
      expect(resource.dig('status', 'replicas')).to eq("#{replicas}".to_i)
      expect(resource.dig('status', 'readyReplicas')).to eq("#{replicas}".to_i)
    end

    # it "has expected chart version" do
    #   expect(resource.dig('metadata', 'labels', 'helm.sh/chart')).to eq("#{chart_name}-#{chart_version}")
    # end

    it "has secret" do
      expect(github_secret.dig('secret', 'secretName')).to eq('registry-credential')
    end
  end

  describe 'webhook creation' do
    before { JSON.parse(`kubectl get mutatingwebhookconfiguration connaisseur-webhook -n connaisseur -o json`) }
    it { expect($?).to be_success }
  end

  describe 'pods' do
    pods = JSON.parse(`kubectl get pods -n kube-system -l "app.kubernetes.io/name=#{app_name}" -o json`)

    pods.dig('items').each do |pod|
      describe pod.dig('metadata', 'name') do

        it "should run on a #{toleration_value} node" do
          expect(pod).to run_on_node_group("#{node_group}")
        end
      end
    end

    it "should be running on different nodes" do
      expect(pods.dig('items').map { |x| x.dig('spec', 'nodeName') }).to be_unique
    end
  end
end
