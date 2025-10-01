String narrative = 'For AAA insurance sales, when a deal is approved, set the opportunity to Closed Won.';
List<String> includeObjects = new List<String>{'Opportunity','Lead','Case'};
RecommendFunctionalities.Response r = RecommendFunctionalities.run(narrative, includeObjects, 3);
System.debug(JSON.serialize(r));