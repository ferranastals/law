{startsWith} = require './util'
generateFilter = require './generateFilter'

getPolicy = (services, policy) ->

  # we'll apply a prefix if we have one
  applyPrefix =
    if policy.filterPrefix
      (name) -> "#{policy.filterPrefix}/#{name}"
    else
      (name) -> name

  # check to see that services used in policy are valid
  validateServices = (serviceNames) ->
    for name in serviceNames
      throw new Error "Error loading policy: '#{name}' is not a valid service name." unless services[name]

  # filter stack by service name
  policyMap = {}
  for name of services
    policyMap[name] = []

  # apply each rule to matching services
  for rule in policy.rules
    throw new Error "Error loading policy: Validations must contain array of filters." unless rule.filters?
    filters = rule.filters.map applyPrefix
    validateServices filters

    if rule.only?
      validateServices rule.only
      for service in rule.only
        policyMap[service].push filters...

    else if rule.except?
      validateServices rule.except

      # don't apply it to the specified rules, or to any other filters
      for service in Object.keys services
        unless (service in rule.except or startsWith service, policy.filterPrefix)
          policyMap[service].push filters...

  return policyMap

applyPolicy = (services, policy) ->

  # get our mapping, same as if we had printed it out
  policyMap = getPolicy services, policy

  # return the original services with the new filters prepended
  wrappedServices = {}
  for name in Object.keys services
    filters = for filter in policyMap[name]
      generateFilter filter, services[filter]
    wrappedServices[name] = services[name]
    wrappedServices[name].prepend filters
  return wrappedServices

module.exports = applyPolicy