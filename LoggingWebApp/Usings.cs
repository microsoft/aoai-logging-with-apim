// Copyright (c) Microsoft. All rights reserved.

global using Azure.Messaging.EventHubs.Producer;
global using LoggingWebApp;
global using Microsoft.AspNetCore.Mvc;
global using Microsoft.Azure.Cosmos;
global using Microsoft.Azure.Cosmos.Fluent;
global using Microsoft.Extensions.Primitives;
global using Microsoft.Net.Http.Headers;
global using Newtonsoft.Json;
global using Newtonsoft.Json.Linq;
global using Serilog;
global using Serilog.Core;
global using Serilog.Events;
global using Serilog.Formatting.Json;
global using Serilog.Sinks.AzCosmosDB;
global using ssetest.Models;
global using System.Diagnostics;
global using System.Text;
global using ILogger = Serilog.ILogger;