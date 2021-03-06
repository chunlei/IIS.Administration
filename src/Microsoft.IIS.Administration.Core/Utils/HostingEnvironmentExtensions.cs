// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.


namespace Microsoft.IIS.Administration.Core
{
    using AspNetCore.Hosting;
    using System.IO;

    public static class HostingEnvironmentExtensions
    {
        public static string ConfigRootPath(this IHostingEnvironment env)
        {
            return Path.GetFullPath(Path.Combine(env.WebRootPath, "..", "config"));            
        }
    }
}