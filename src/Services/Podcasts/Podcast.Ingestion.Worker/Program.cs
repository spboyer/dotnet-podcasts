using Azure.Identity;
using Podcast.Infrastructure;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration(configuration => {
        var credential = new ChainedTokenCredential(new AzureDeveloperCliCredential(), new DefaultAzureCredential());
        configuration.AddAzureKeyVault(new Uri(Environment.GetEnvironmentVariable("AZURE_KEY_VAULT_ENDPOINT")!), credential);
    })
    .ConfigureServices((hostContext, services) =>
    {
        services.AddSql<PodcastDbContext>(hostContext.Configuration, new SqlConfig
        {
            RetryOnFailure = true,
            RetryCount = 5,
            RetryDelay = TimeSpan.FromSeconds(10),
            CommandTimeout = 10,
        });
        var feedQueueClient = new QueueClient(hostContext.Configuration[hostContext.Configuration["AZURE_FEED_QUEUE_CONNECTION_STRING_KEY"]], "feed-queue");
        feedQueueClient.CreateIfNotExists();
        services.AddSingleton(feedQueueClient);
        services.AddScoped<IPodcastIngestionHandler, PodcastIngestionHandler>();
        services.AddHttpClient<IFeedClient, FeedClient>();
        services.AddHostedService<Worker>();
    })
    .Build();

await host.RunAsync();