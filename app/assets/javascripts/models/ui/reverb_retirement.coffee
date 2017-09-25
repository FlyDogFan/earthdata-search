#= require util/js.cookies
#= require util/metrics

ns = @edsc.models.ui
data = @edsc.models.data

ns.ReverbRetirement = do (ko) ->
  class ReverbRetirement
    constructor: ->

    referrerIsReverb: () =>
      console.log "Checking referrer: " + document.referrer
      referrer = if document.referrer then document.referrer.match(/:\/\/(.[^/]+)/)[1] else false
      reverb = ["echo-reverb-rails.dev", "testbed.echo.nasa.gov", "api-test.echo.nasa.gov", "testbed.echo.nasa.gov", "reverb.echo.nasa.gov"]
      return $.inArray(referrer, reverb) != -1 

    returnToReverb: (source = 'modal link') =>
      Cookies.set('ReadyForReverbRetirement', 'false', { expires: 90 })
      # metrics go here once it's figured out...
      # metrics_event('reverb_redirect', 'back_to_reverb', {source: source}) 
      window.location.replace("https://" + document.referrer.match(/:\/\/(.[^/]+)/)[1])
    
    stayWithEDSC: () =>
      Cookies.set('ReadyForReverbRetirement', 'true', { expires: 90 })
      # metrics go here once it's figured out...
      # metrics_event('reverb_redirect', 'stay_in_edsc') %>
      $('#reverbRetirementModal').modal('hide')
    
  exports = ReverbRetirement