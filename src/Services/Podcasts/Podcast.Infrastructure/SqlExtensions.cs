using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Podcast.Infrastructure;

public class SqlConfig
{
    public bool RetryOnFailure { get; set; }
    public int RetryCount { get; set; }
    public TimeSpan RetryDelay { get; set; }
    public int CommandTimeout { get; set; }
}

public static class SqlExtensions
{
    public static IServiceCollection AddSql<T>(
        this IServiceCollection serviceCollection,
        IConfiguration configuration,
        SqlConfig? config = null) where T : DbContext
    {
        var dataStore = configuration["DATA_STORE"] ?? "SQLServer";
        switch (dataStore)
        {
            case "SQLServer":
            {
                var connectionString = configuration["AZURE_API_SQL_CONNECTION_STRING_KEY"];
                serviceCollection.AddSqlServer<T>(connectionString, options =>
                {
                    if (config == null) return;
                    if (config.RetryOnFailure)
                    {
                        options.EnableRetryOnFailure(config.RetryCount, config.RetryDelay, null);
                    }
                    options.CommandTimeout(config.CommandTimeout);
                });
                break;
            }
            case "PostgreSQL":
            {
                var pgHost = configuration["POSTGRES_HOST"];
                var pgPassword = configuration["POSTGRES_PASSWORD"];
                var pgUser = configuration["POSTGRES_USERNAME"];
                var pgDatabase = configuration["POSTGRES_DATABASE"];
                var pgConnection = $"Host={pgHost};Database={pgDatabase};Username={pgUser};Password={pgPassword};Timeout=300";
                serviceCollection.AddNpgsql<T>(pgConnection, options =>
                {
                    if (config == null) return;
                    if (config.RetryOnFailure)
                    {
                        options.EnableRetryOnFailure(config.RetryCount, config.RetryDelay, null);
                    }
                    options.CommandTimeout(config.CommandTimeout);
                });
                break;
            }
            default:
                throw new ArgumentException($"Invalid data store: {dataStore}");
        }
        return serviceCollection;
    }
}