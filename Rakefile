# refer to https://github.com/mfenner/jekyll-travis
require 'yaml'

CONFIG = YAML.load(File.read('_config.yml'))
USERNAME = CONFIG["username"]
REPO = CONFIG["repo"] || "#{USERNAME}.github.io"

# Determine source and destination branch
# User or organization: source -> master
# Project: master -> gh-pages
# Name of source branch for user/organization defaults to "source"
if REPO == "#{USERNAME}.github.io"
  SOURCE_BRANCH = CONFIG['branch'] || "source"
  DESTINATION_BRANCH = "master"
else
  SOURCE_BRANCH = "master"
  DESTINATION_BRANCH = "gh-pages"
end

# rake site:deploy
namespace :site do
  desc "Generate the site and push changes to remote origin"
  task :deploy do
    # Make sure destination folder exists as git repo
    sh "bundle exec jekyll clean"

    unless Dir.exist? CONFIG["destination"]
      sh "git clone git@github.com:#{USERNAME}/#{REPO}.git #{CONFIG["destination"]}"
    end

    Dir.chdir(CONFIG["destination"]) { sh "git checkout #{DESTINATION_BRANCH}" }

    # Generate the site
    sh "JEKYLL_ENV=production bundle exec jekyll build"

    # Commit and push to github
    sha = `git log`.match(/[a-z0-9]{40}/)[0]
    Dir.chdir(CONFIG["destination"]) do
      sh "git add --all ."
      sh "git config user.name '#{USERNAME}'"
      sh "git config user.email #{CONFIG["email"]}"
      sh "git commit -m 'Updating to #{USERNAME}/#{REPO}@#{sha}.'"
      sh "git push --quiet origin #{DESTINATION_BRANCH}"
      puts "Pushed updated branch #{DESTINATION_BRANCH} to GitHub Pages"
    end
    sh "bundle exec jekyll clean"
  end
end