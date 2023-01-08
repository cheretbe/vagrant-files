### Tests

* https://github.com/hashicorp/vagrant/blob/main/test/unit/plugins/provisioners/docker/config_test.rb
* https://relishapp.com/rspec/rspec-mocks/docs/basics
    * https://relishapp.com/rspec/rspec-mocks/docs/setting-constraints/receive-counts
* https://www.rubyguides.com/2018/10/rspec-mocks/
* https://josh.works/mocks-stubs-exceptions-ruby
* https://en.wikibooks.org/wiki/Ruby_Programming/Unit_testing
* https://www.cloudbees.com/blog/unit-testing-in-ruby
* https://dev.to/oinak/mocks-and-stubs-in-ruby-unit-tests-a-cheatsheet-pgh

```shell
cd tools/docker/ruby-vagrant/
docker build -t ruby-vagrant .

cd ../../..
docker run --rm -ti -v $(pwd)/lib:/vagrant_lib ruby-vagrant:latest
cd /vagrant_lib/
rspec --format doc
```
