// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.


namespace Microsoft.IIS.Administration.Logging
{
    using Core;
    using Extensions.Logging;
    using Extensions.DependencyInjection;
    using Serilog;
    using System.IO;
    using AspNetCore.Hosting;
    using Serilog.Events;
    using Extensions.Configuration;

    public static class LoggingExtensions
    {
        public static IServiceCollection AddApiLogging(this IServiceCollection services)
        {
            var sp = services.BuildServiceProvider();
            var config = sp.GetRequiredService<IConfiguration>();
            var appBasePath = sp.GetRequiredService<IHostingEnvironment>().ContentRootPath;
            var defaultLogsRoot = Path.GetFullPath(Path.Combine(appBasePath, "logs"));

            var loggingConfiguration = new LoggingConfiguration(config);
            var logsRoot = loggingConfiguration.LogsRoot;
            var minLevel = loggingConfiguration.MinLevel;

            // If invalid directory was specified in the configuration. Reset to default
            if (!Directory.Exists(logsRoot)) {
                logsRoot = defaultLogsRoot;
            }

            if (!loggingConfiguration.Enabled) {
                // Disable logging
                minLevel = (LogLevel)(1 + (int)LogEventLevel.Fatal);
            }

            Log.Logger = new LoggerConfiguration()
                .MinimumLevel
                .Is(LoggingConfiguration.ToLogEventLevel(minLevel))
                .WriteTo
                .RollingFile(Path.Combine(logsRoot, loggingConfiguration.FileName), retainedFileCountLimit: null)
                .CreateLogger();

            ILoggerFactory loggerFactory = services.BuildServiceProvider().GetRequiredService<ILoggerFactory>();
            loggerFactory.AddSerilog();

            return services;
        }

        public static IServiceCollection AddApiAuditing(this IServiceCollection services)
        {
            var sp = services.BuildServiceProvider();
            var config = sp.GetRequiredService<IConfiguration>();
            var appBasePath = sp.GetRequiredService<IHostingEnvironment>().ContentRootPath;
            var defaultAuditRoot = Path.GetFullPath(Path.Combine(appBasePath, "logs"));

            var auditingConfiguration = new AuditingConfiguration(config);
            var auditRoot = auditingConfiguration.AuditingRoot;
            var minLevel = auditingConfiguration.MinLevel;

            // If invalid directory was specified in the configuration. Reset to default
            if (!Directory.Exists(auditRoot)) {
                auditRoot = defaultAuditRoot;
            }

            if (!auditingConfiguration.Enabled) {
                // Disable auditing
                minLevel = (LogLevel)(1 + (int)LogEventLevel.Fatal);
            }

            AuditAttribute.Logger = new LoggerConfiguration()
                .MinimumLevel
                .Is(LoggingConfiguration.ToLogEventLevel(minLevel))
                .WriteTo
                .RollingFile(Path.Combine(auditRoot, auditingConfiguration.FileName), retainedFileCountLimit: null)
                .CreateLogger();

            return services;
        }
    }
}
