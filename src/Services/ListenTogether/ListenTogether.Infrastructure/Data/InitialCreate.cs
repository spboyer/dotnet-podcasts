using Microsoft.Extensions.Configuration;

namespace ListenTogether.Hub.Infrastructure.Data.Migrations
{

    public static class DataHelper 
    {
        static IConfigurationBuilder builder = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
            .AddEnvironmentVariables();
        static IConfigurationRoot configuration = builder.Build();

        private static string dataStore = configuration["DATA_STORE"] ?? "SQLServer";
                //"SQLServer":
                //"PostgreSQL":

        public static string idTypeName 
        { 
            get 
            {   
                switch (dataStore)
                {
                    case "SQLServer":
                        return "uniqueidentifier";
                    case "PostgreSQL":
                        return "uuid";
                    default:
                        throw new ArgumentException($"Invalid data store: {dataStore}");
                }
            } 
        }

        public static string boolTypeName 
        { 
            get 
            {   
                switch (dataStore)
                {
                    case "SQLServer":
                        return "bit";
                    case "PostgreSQL":
                        return "boolean";
                    default:
                        throw new ArgumentException($"Invalid data store: {dataStore}");
                }
            } 
        }
    }

    public partial class InitialCreate
    {
       
        public string idTypeName 
        { 
            get { return DataHelper.idTypeName; } 
        }

        public string boolTypeName 
        { 
            get { return DataHelper.boolTypeName;}
        }
        
   }

   public partial class ListenTogetherDbContextModelSnapshot
   {

        public string idTypeName 
        { 
            get { return DataHelper.idTypeName; } 
        }

        public string boolTypeName 
        { 
            get { return DataHelper.boolTypeName;}
        }
   }
}