{
  "type": "website",
  "bypassNetworkLists": [
    {
      "id": "${securitybypass_list}"
    }
  ],
  "configId": "${config_id}",
  "defaultFile": "NO_MATCH",
  "effectiveSecurityControls": {
    "applyApplicationLayerControls": true,
    "applyNetworkLayerControls": true,
    "applyRateControls": true,
    "applySlowPostControls": true
  },
  "filePaths": [
    "/*"
  ],
  "hostnames": "${jsonencode(hostnames)}",
  "isNegativeFileExtensionMatch": false,
  "isNegativePathMatch": false,
  "securityPolicy": {
    "policyId": "${policy_id}"
  }
}