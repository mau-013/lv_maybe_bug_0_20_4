# lv_maybe_bug_0_20_4
Simple Phoenix app to demonstrate what may be a bug starting with Liveview 0.20.4 on form submission.

The app is a basic setup of a liveview with a live_component, both of which have a form in them. The parent form is fed with the component's data.
State is kept on the parent form.

```
# the setup started from the following generators
mix phx.new
mix phx.gen.live Accounts User users name:string age:integer internal_value:string

# the output is then heavily simplified and the liveview is altered to fit the parent - component setup
# there is no DB setup - the Repo is commented out on application.ex, so no ecto create or migration required
```

On a "Save User" click (the button is from the component form), the data is sent to the parent liveview, a changeset is created+validated, if vlaid the parent form is updated and finally a POST request is started by a manual trigger of the parent form.

The data that is passed on to the POST request is shown on screen afterwards.

This code works with Liveview versions prior to 0.20.4
(the mix.exs is ready to uncomment the working and not working versions)

Is this a bug? Or was this code dependant on an bug that was fixed with this release?
