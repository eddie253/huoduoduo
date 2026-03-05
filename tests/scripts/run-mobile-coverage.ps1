$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\.."
npm run mobile:test:coverage
npm run mobile:coverage:check
