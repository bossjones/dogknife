dogknife
========

    (n) A sweet integration between knife and datadog
    
[Datadog](http://www.datadoghq.com) already instruments your [Chef](http://opscode.com/chef) runs.
Now, with `dogknife`, instrument your knife commands to know who runs what and when.

Getting Started
===============

1. If you are not a Datadog user yet, [sign up](http://www.datadoghq.com/signup)
2. Get your [API key](https://app.datadoghq.com/account/settings) and your Datadog handle.
3. Configure them as `datadog_api_key` and `datadog_user` in your knife configuration file (usually in `~/.chef/knife.rb`)
4. Install `dogknife` with `gem install dogknife`
5. Use `dogknife` where you would use `knife`