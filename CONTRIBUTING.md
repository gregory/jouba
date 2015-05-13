# Contributing to Jouba

You're encouraged to submit [pull requests](https://github.com/gregory/jouba/pulls), [propose features, and discuss issues](https://github.com/gregory/jouba/issues).

We'll use issues to manage anything that is code related: bugs or features so please, before doing anything, create a new issue and make sure this is not a duplaction.
If this is not code related(readme or other stuffs), a pull request is enough.

If this is a bug, explain the issue(short description is better), add the bug label then open a pull request that reproduce that bug.

If this is a feature, please explain what you are trying to do, add the feature label then open a pull request with a spec that would show what you want to do

At this point, your spec should be failing.

Here is how to open a pull request:

#### Fork the Project

Fork the [project on Github](https://github.com/gregory/jouba) and check out your copy.

```
git clone https://github.com/CONTRIBUTOR/jouba.git
cd jouba
git remote add upstream https://github.com/gregory/jouba.git
```

#### Create a Feature Branch

Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.
Make sure your branch is prefixed by the related issue number

```
git checkout master
git pull upstream master
git checkout -b issue_2_improve_something
```

#### Bundle Install and Test

Ensure that you can build the project and run tests.

```
bundle install
bundle exec rake
```

#### Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build.

If this is an issue, try to reproduce the problem you are trying to fix or describes in `specs/issues/`.

Please prefix it with the **issue number**  and a short description.

Ex: let's say there is an issue opened in Aggregate#emit (let's say issue num 4):

```rb
# in specs/issues/aggregate.rb
require 'spec_helper'
require 'jouba/aggregate'

describe Jouba::Aggregate do
  describe '#emit()' do
    context 'special context' do
      describe "#4: [the issue]" do
      end
    end
  end
end
```

If this is a feature you want to build, try to highlight it in `specs/features`.
Ex: let's say you want to add new behaviour on Aggregate#emit (discussed on issue 5)

```rb
# in specs/issues/aggregate.rb
require 'spec_helper'
require 'jouba/aggregate'

describe Jouba::Aggregate do
  describe '#emit()' do
    describe "#5: [what is the new behaviour]" do
    end
  end
end
```

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

#### Write Code

Implement your feature or bug fix.

Ruby style is enforced with [Rubocop](https://github.com/bbatsov/rubocop), run `bundle exec rubocop` and fix any style issues highlighted.

Make sure that `bundle exec rake` completes without errors.

#### Write Documentation

Document any external behavior in the [README](README.md).

#### Update Changelog

Add a line to [CHANGELOG](CHANGELOG.md) under *Next Release*. Make it look like every other line, including your name and link to your Github account.

#### Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed and why.
Please make sure to prepend your commit message with `Issue **issue number**`
ex of commit message: '#5 - Description of the feature or issue'

```
git add ...
git commit
```

#### Push

```
git push origin my-feature-branch
```

#### Make a Pull Request

Go to https://github.com/contributor/jouba and select your feature branch. Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days.

#### Rebase

If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

#### Update CHANGELOG Again

Update the [CHANGELOG](CHANGELOG.md) with the pull request number. A typical entry looks as follows.

```
* [#123](https://github.com/CONTRIBUTOR/pull/123): [Added products resource](https://github.com/issues/100) - [@contributor](https://github.com/contributor).
```

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

#### Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed muster with Travis-CI. Everything should look green, otherwise fix issues and amend your commit as described above.
