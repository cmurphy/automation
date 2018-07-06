require_relative 'ia_cloud'

module GithubPR
  class JenkinsJobTriggerArdanaTestbuildAction < JenkinsJobTriggerAction
    def extra_parameters(pull, _build_mode = "")
      {
        github_repo: @metadata[:repository],
        github_org: @metadata[:organization],
        github_pr: "#{pull.number}:#{pull.head.sha}:#{pull.base.ref}",
        job_name: "#{@metadata[:org_repo]} testbuild PR #{pull.number} #{pull.head.sha[0,8]}",
        emit_success: "#{ENV['emit_success']}"
      }
    end
  end
end
