function select_staging_project() {
    local staging_project
    if [ -n "${github_pr:-}" ] ; then
        staging_project=home:comurphy:Fake:Cloud:8:${github_pr}
    else
        staging_project=home:comurphy:Fake:Cloud:8:A
    fi
    echo $staging_project
}

select_staging_project
