# Renv

The name stands for "Remote ENVironment" (thanks, captain obvious).

`renv` manages your `.env` (envrionment variables) files so they are never stored on your local machine.

It can be used to provide a replacement to Heroku's superb `config:get` /
`config:set` in Capistrano-land.


## Installation

You know the dance:

    $ gem install renv

You may need in your application's Gemfile, of course.

## Configuration

You will need to set at least two variables in your environment:

    RENV_AWS_KEY_myapp=...
    RENV_AWS_SECRET_myapp=...

Plus a few optional ones (can be overriden on the command-line):

    RENV_APP=myapp
    RENV_BUCKET_myapp=...

## Usage

    Commands:
      renv del KEY...        # deletes KEY and its value
      renv dump              # dumps all key-value pairs in .env format
      renv get KEY           # returns the value of KEY
      renv help [COMMAND]    # Describe available commands or one specific command
      renv load              # set keys from standard input in .env format
      renv set KEY=VALUE...  # sets the value of KEY to VALUE

    Options:
      -a, [--app=APP]        # Application name, defaults to RENV_APP
      -b, [--bucket=BUCKET]  # S3 bucket storing environment(s), defaults to RENV_BUCKET_<app>
      -n, [--name=NAME]      # Environment name, e.g. for staging apps, defaults to app name

## How it works

Simply enough:

- `get` and `dump` will read a `.env`-formatted file from S3 (and parse it, in
  the case of `get`)
- `set`, `load`, and `del` will write them back.

Every time a write to S3 occurs, two files get written: one named `latest` (all
read operations look at this file), and one named with the current ISO timestamp
(for backup purposes... in case you delete a needed key!)

**Caveat:** No effort is made to be safeguard against multiple users writing at
the same time.


## Hooking to Capistrano

Here's an example, assuming you use the multistage extensions:

```ruby
after 'deploy:finalize_update' do
  environment = %x(bundle exec renv dump -a my_app -b my_bucket -n #{stage})
  unless $?.success?
    warn "Failed to obtain environment variables"
    exit 1
  end
  put environment, "#{release_path}/.env"
end
```

The environment variables will briefly live in Capistrano's memory, but will not
be saved to your disk.

## Contributing

Yes, please!

1. Fork it ( https://github.com/HouseTrip/renv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
