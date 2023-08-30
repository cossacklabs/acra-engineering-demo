# Client-side encryption, Ruby on Rails app, PostgreSQL

Ruby on Rails web application, client-side encryption, AcraServer, PostgreSQL database.

## 1. Installation

```bash
curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- rails
```

This command downloads a Rails application that stores data in a database, Acra Docker containers, PostgreSQL database, Prometheus,
Grafana, pgAdmin. Additionally, downloads a memcached and Elastic as project dependencies, sets up the environment, and provides a list of links for you to try.

## 2. What's inside


**The client application** is a [rubygems.org fork](https://github.com/cossacklabs/rubygems.org) that works with a database. The application **encrypts** the data in AcraStructs before sending it to a database. The application **reads** the decrypted data through AcraServer (that are transparent for the application).

### 2.1 Prepare

1. Sign up with any fictional account at [sign_up page](http://www.rubygems.example:8000/sign_up) of the app. That credentials will be used later when uploading gem.

2. Verify your fictional email on a [special page](http://www.rubygems.example:8000/rails/mailers/mailer/email_confirmation) for development purposes.

3. Sign in via `gem` CLI tool with credentials used in the step 2:

```
gem signin --host=http://www.rubygems.example:8000
```

4. Use already built gem `rails/my-example-gem-0.1.0.gem` or build your own:

```bash
bundle gem my-example-gem
cd my-example-gem/

cat > ./my-example-gem.gemspec <<'EOF'
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "my/example/gem/version"

Gem::Specification.new do |spec|
  spec.name          = "my-example-gem"
  spec.version       = My::Example::Gem::VERSION
  spec.authors       = ["My Example Name"]
  spec.email         = ["my@email.example"]

  spec.summary       = %q{Example Gem}
  spec.description   = %q{This is Example Gem}
  spec.homepage      = "http://site.example"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "http://site.example"
    spec.metadata["changelog_uri"] = "http://site.example/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
EOF

gem build my-example-gem
```

### 2.2 Write data

Now we are ready to push our gem to the application:
```
gem push my-example-gem-0.1.0.gem --host=http://www.rubygems.example:8000
```

### 2.3 Read data

After previous step we can see information about uploaded gem: http://www.rubygems.example:8000/gems/my-example-gem

### 2.4 Read the data directly from the database

1. Log into web PostgreSQL interface [http://www.rubygems.example:8008](http://www.rubygems.example:8008) using user/password: `test@test.test`/`test`.

2. Go to the `Servers > postgresql > databases > rubygems > Schemas > public > Tables > versions` and open context menu with right-click. Select `View/Edit Data > All rows` and now you can see content of the table.
<p align="center"><img src="_pics/eng_demo_rails_pdadmin.png" alt="pgAdmin : versions table of rubygems DB." width="900"></p>
Fields `authors`, `description` and `summary` are encrypted. So, the data is stored in an encrypted form, but it is transparent for the Rails application.

### 2.5 Other available resources

1. PostgreSQL – connect directly to the database using the admin account `rubygems`/`rubygems`: [postgresql://www.rubygems.example:5432](postgresql://localhost:5432).

2. pgAdmin - connect directly to the database using WebUI and user account login:`test@test.test`/password:`test`: [http://localhost:8008](http://localhost:8008)

3. Prometheus –  examine the collected metrics: [http://localhost:9090](http://localhost:9090).

4. Grafana – see the dashboards with Acra metrics: [http://localhost:3000](http://localhost:3000).

5. Jaeger – view traces: [http://localhost:16686](http://localhost:16686).

6. AcraServer – send some data directly through AcraServer: [tcp://www.rubygems.example:9393](tcp://localhost:9494).

## 3. Show me the code!

1. Add gem `activerecord_acrawriter` to `Gemfile`:
```diff
+gem 'activerecord_acrawriter'
```

2. Modify `dependency.rb` to encrypt data of `unresolved_name` column in `Dependency` model:
```diff
@@ -1,3 +1,5 @@
+require 'activerecord_acrawriter'
+
 class Dependency < ApplicationRecord
   belongs_to :rubygem
   belongs_to :version
@@ -11,6 +13,8 @@

   attr_accessor :gem_dependency

+  attribute :unresolved_name, AcraType.new
+
   def self.unresolved(rubygem)
     where(unresolved_name: nil, rubygem_id: rubygem.id)
   end
```

3. And finally modify `version.rb` encrypt data of `authors`, `description` and `summary` columns in `Version` model:
```diff
@@ -1,4 +1,5 @@
 require 'digest/sha2'
+require 'activerecord_acrawriter'

 class Version < ApplicationRecord
   belongs_to :rubygem, touch: true
@@ -21,7 +22,7 @@
   validate :authors_format, on: :create
   validate :metadata_links_format

-  class AuthorType < ActiveModel::Type::String
+  class AuthorType < AcraType
     def cast_value(value)
       if value.is_a?(Array)
         value.join(', ')
@@ -32,3 +33,5 @@
   end

   attribute :authors, AuthorType.new
+  attribute :description, AcraType.new
+  attribute :summary, AcraType.new
```

These are all the code changes! 🎉

---
