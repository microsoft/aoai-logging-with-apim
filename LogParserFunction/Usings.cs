// Copyright (c) Microsoft. All rights reserved.

global using Azure.AI.ContentSafety;
global using Azure.Messaging.EventHubs.Processor;
global using LogParser.Extensions;
global using LogParser.Models;
global using LogParser.Models.ChatCompletion;
global using LogParser.Models.ChatCompletion.Stream;
global using LogParser.Models.ChatCompletion.Vision;
global using LogParser.Models.Completion;
global using LogParser.Models.ContentSafety;
global using LogParser.Models.Embedding;
global using LogParser.Services;
global using Microsoft.ApplicationInsights.Extensibility;
global using Microsoft.Azure.Cosmos;
global using Microsoft.Azure.Cosmos.Fluent;
global using Newtonsoft.Json;
global using Newtonsoft.Json.Linq;
global using Serilog;
global using Serilog.Formatting.Json;
global using System.Text;
global using TiktokenSharp;
global using SixLabors.ImageSharp;
global using SixLabors.ImageSharp.Processing;
global using Microsoft.Extensions.Hosting;
global using Microsoft.Azure.Functions.Worker;
