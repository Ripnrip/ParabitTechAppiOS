//
// Copyright 2014-2017 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License").
// You may not use this file except in compliance with the
// License. A copy of the License is located at
//
//     http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, express or implied. See the License
// for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import AWSCognitoIdentityProvider

#if DEBUG
    let CognitoIdentityUserPoolRegion: AWSRegionType = .USEast1
    let CognitoIdentityUserPoolId = "us-east-1_x7DbaNO9e"
    let CognitoIdentityUserPoolAppClientId = "4av5nbdtdmvlb0an3r5mjnoekf"
    let CognitoIdentityUserPoolAppClientSecret = "52dm0r5k2g2rmm6s401ato7ltni4rara4isl1p4qhm4keqq594e"
#else
    let CognitoIdentityUserPoolRegion: AWSRegionType = .USEast1
    let CognitoIdentityUserPoolId = "us-east-1_FuLhTJM6N"
    let CognitoIdentityUserPoolAppClientId = "7udrug812mcut3o4ot2h5dkphi"
    let CognitoIdentityUserPoolAppClientSecret = "10c7m9jlk57pivavvap97p45dgb5tubrap5i1uglu5oohqk5lo1d"
#endif

let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
