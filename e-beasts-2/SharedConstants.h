//
//  SharedConstants.h
//  tendril-test
//
//  Created by Beaudry Kock on 8/13/12.
//  Copyright (c) 2012 Beaudry Kock / Better World Coding. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.

// MODIFY IF NEEDED
#define BKDEBUG // comment out to remove debugging NSLog calls
#define BKDEBUG_VERBOSE // comment out to remove verbose debugging NSLog calls
#define tendrilBaseURL @"https://dev.tendrilinc.com"

// NOTES...
// 1. see dev.tendrilinc.com for full API details
// 2. Full capabilities available at http://dev.tendrilinc.com/oauth/capabilities

// **FOR TESTING, DO NOT MODIFY**
#define PASSWORD @"password"
#define X_ROUTE @"sandbox"
#define GRANT_TYPE @"password"

// **MODIFY THESE**
//#warning Add your app key
#define CLIENT_ID @"ba5f0303bcb743744073f850390a0132" // app key

//#warning Add your app secret
#define CLIENT_SECRET @"1ffeb69e6c28b027aec7fa80e1cfea1a" // app secret

// **MODIFY THESE WITH PREFERRED USER FROM http://dev.tendrilinc.com/docs/sample_users**
#define USERNAME @"kurt.cobain@tendril.com"
#define USER_ID 55
#define EXTERNAL_ACCOUNT_ID @"aid_kc"

// Use short_lived for 3 second access token, to test refresh code
// other options: short_lived, user_information, location, consumption, pricing, device, user_profile, comparisons, greenbutton, offline_access
#define SCOPE @"consumption"

// projected consumption resolution options
#define kWeekly @"WEEKLY"
#define kMonthly @"MONTHLY"
#define kYearly @"YEARLY"
#define kBillCycle @"BILL_CYCLE"

// DO NOT MODIFY
// CONNECTION TYPES
#define kAuthorization 0
#define kConsumption 1
#define kUserInformation 2
#define kMeterReading 3
#define kConsumptionProjection 4