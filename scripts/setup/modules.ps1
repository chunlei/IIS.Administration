# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.


Param (
    [parameter(Mandatory=$true , Position=0)]
    [ValidateSet("Get-JsonContent",
                 "Serialize",
                 "Deserialize",
                 "Add-NewModules",
                 "Set-JsonContent")]
    [string]
    $Command,
    
    [parameter()]
    [string]
    $Path,
    
    [parameter()]
    [System.Array]
    $OldModules,
    
    [parameter()]
    [System.Array]
    $NewModules,
    
    [parameter()]
    [System.Object]
    $JsonObject,
    
    [parameter()]
    [string]
    $Value
)

# Returns an object representation parsed from the given string.
# Value: The string value to parse.
function Deserialize($_content) {
    $fromJsonCommand = Get-Command "ConvertFrom-Json" -ErrorAction SilentlyContinue
    if ($fromJsonCommand -ne $null) {
        ConvertFrom-Json $_content
    }
    else {
        Add-Type -assembly System.Web.Extensions
        $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $serializer.DeserializeObject($_content)
    }
}

# Returns the JSON representation of an object as a string.
# JsonObject: The object to serialize.
function Serialize($_jsonObject) {
    $toJsonCommand = Get-Command "ConvertTo-Json" -ErrorAction SilentlyContinue
    if ($toJsonCommand -ne $null) {
        ConvertTo-Json $_jsonObject -Depth 100
    }
    else {
        Add-Type -assembly System.Web.Extensions
        $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $serializer.Serialize($_jsonObject)
    }
}

# Returns the content of a file formatted with JSON as an object.
# Path: The path to the file.
function Get-JsonContent($_path)
{
	if ([System.String]::IsNullOrEmpty($_path)) {
		throw "Path required"
	}

    if (-not(Test-Path $_path)) {
        throw "$_path not found."
    }

    $lines = Get-Content $Path

    $content = ""

    foreach ($line in $lines) {
        $content += $line
    }

    Deserialize $content
}

# Serializes an object and sets the content of the file at the given path to the serialized output.
# Path: The path of the file to write the JSON result to.
# JsonObject: The object to serialize.
function Set-JsonContent($_path, $jsonObject) {

	if ([System.String]::IsNullOrEmpty($_path)) {
		throw "Path required"
	}

    if ($jsonObject -eq $null) {
        throw "JsonObject required"
    }

    New-Item -Type File $_path -Force -ErrorAction Stop | Out-Null
    
    Serialize $jsonObject | Out-File $_path -ErrorAction Stop
}

function To-HashObject($o) {
    $ret = @{}
    foreach ($key in $o.keys) { $ret.$key = $o.$key }
    return $ret
}

# Given two arrays of modules, The union of the two are returned.
# OldModules: The original modules list.
# NewModules: The new modules list used to update.
function Add-NewModules($_oldModules, $_newModules) {

    if ($_oldModules -eq $null) {
        throw "OldModules required"
    }

    if ($_newModules -eq $null) {
        throw "NewModules required"
    }

    $ms = New-Object "System.Collections.ArrayList"
    foreach ($module in $_oldModules) {
        $ms.Add($(To-HashObject($module))) | out-null
    }
    
    foreach ($module in $_newModules) {
        $exists = $false

        foreach ($oldModule in $_oldModules) {

            if ($oldModule.name -eq $module.name) {
                $exists = $true
                break
            }
        }

        if (-not($exists)) {
            $ms.Add($(To-HashObject($module))) | out-null
        }
    }

    Serialize($ms)
}

switch ($Command)
{
    "Add-NewModules"
    {
        return Add-NewModules $OldModules $NewModules
    }
    "Get-JsonContent"
    {
        return Get-JsonContent $Path
    }
    "Set-JsonContent"
    {
        Set-JsonContent $Path $JsonObject
    }
    "Serialize"
    {
        Serialize $JsonObject
    }
    "Deserialize"
    {
        Deserialize $Value
    }
    default
    {
        throw "Unknown command"
    }
}

