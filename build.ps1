function BuildVariants {
  param (
    $builder,
    $ldflags,
    $compileflags,
    $prefix,
    $suffix,
    $arch,
    $os,
    $path
  )

  foreach ($currentarch in $arch) {
    foreach ($currentos in $os) {
      $env:GOARCH = $currentarch
      $env:GOOS = $currentos

      # More sensible naming for x64
      $namearch = $currentarch
      if ($namearch -eq "amd64") {
        $namearch = "x64"
      }

      $outputfile = "binaries/$prefix-$currentos-$namearch$suffix"
      if ($currentos -eq "windows") {
        $outputfile += ".exe"
      }

      & $builder build -ldflags "$ldflags" -o $outputfile $compileflags $path
      if (Get-Command "cyclonedx-gomod" -ErrorAction SilentlyContinue)
      {
        cyclonedx-gomod app -json -licenses -output $outputfile.bom.json -main $path .
      }
    }
  }
}

Set-Location $PSScriptRoot

# Release
BuildVariants -builder go -ldflags "$LDFLAGS -s" -prefix ldapnomnom -path . -arch @("386", "amd64", "arm64") -os @("windows", "darwin", "linux")

$env:GOGARBLE="github.com/lkarlslund"

BuildVariants -builder garble -ldflags "$LDFLAGS -s" -prefix ldapnomnom -path . -arch @("386", "amd64", "arm64") -os @("windows", "darwin", "linux") -suffix "-obfuscated"
