using Azure.Identity;
using Microsoft.Extensions.Configuration;
using Podcast.Infrastructure;
using Podcast.Updater.Worker;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration(configuration => {
        var credential = new ChainedTokenCredential(new AzureDeveloperCliCredential(), new DefaultAzureCredential());
        configuration.AddAzureKeyVault(new Uri(Environment.GetEnvironmentVariable("AZURE_KEY_VAULT_ENDPOINT")!), credential);
    })
    .ConfigureServices((hostContext, services) =>
    {
        services.AddHostedService<Worker>();
        services.AddSql<PodcastDbContext>(hostContext.Configuration, new SqlConfig
            {
                RetryOnFailure = true,
                RetryCount = 10,
                RetryDelay = TimeSpan.FromSeconds(60),
                CommandTimeout = 30,
            })
            .AddTransient<IPodcastUpdateHandler, PodcastUpdateHandler>()
            .AddHttpClient<IFeedClient, FeedClient>()
            .Services
            .AddLogging();
    })
    .Build();

await host.RunAsync();