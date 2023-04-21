using ListenTogether.Application.Interfaces;
using ListenTogether.Infrastructure.Data;
using ListenTogether.Infrastructure.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace ListenTogether.Infrastructure
{
    public static class ServiceCollectionsExtensions
    {
        public static IServiceCollection AddInfrastructure(this IServiceCollection serviceCollection, IConfiguration configuration)
        {
            serviceCollection.AddSql<ListenTogetherDbContext>(configuration);
            serviceCollection.AddScoped<IApplicationDbContext, ListenTogetherDbContext>();
            serviceCollection.AddHttpClient<IEpisodesClient, EpisodesHttpClient>(opt =>
            {
                opt.BaseAddress = new Uri(configuration["REACT_APP_API_BASE_URL"]);
                opt.DefaultRequestHeaders.Add("api-version", "1.0");
            });

            return serviceCollection;
        }

        private static IServiceCollection AddSql<T>(this IServiceCollection serviceCollection, IConfiguration configuration) where T : DbContext
        {
            var dataStore = configuration["DATA_STORE"] ?? "SQLServer";
            
            switch (dataStore)
            {
                case "SQLServer":
                {
                    var connectionString = configuration["AZURE_HUB_SQL_CONNECTION_STRING_KEY"];
                    serviceCollection.AddSqlServer<T>(connectionString);
                    break;
                }
                case "PostgreSQL":
                {
                    var pgHost = configuration["POSTGRES_HOST"];
                    var pgPassword = configuration["POSTGRES_PASSWORD"];
                    var pgUser = configuration["POSTGRES_USERNAME"];
                    var pgDatabase = configuration["POSTGRES_DATABASE"];
                    var pgConnection = $"Host={pgHost};Database={pgDatabase};Username={pgUser};Password={pgPassword};Timeout=300";
                    serviceCollection.AddNpgsql<T>(pgConnection, options => options.EnableRetryOnFailure());
                    break;
                }
                default:
                    throw new ArgumentException($"Invalid data store: {dataStore}");
            }
            return serviceCollection;
        }
    }
}