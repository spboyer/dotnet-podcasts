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

        public static string IdTypeName 
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

        public static string BoolTypeName 
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

        public static string StringTypeName
        { 
            get 
            {   
                switch (dataStore)
                {
                    case "SQLServer":
                        return "nvarchar(max)";
                    case "PostgreSQL":
                        return "text";
                    default:
                        throw new ArgumentException($"Invalid data store: {dataStore}");
                }
            } 
        }

        public static string DateTimeTypeName
        { 
            get 
            {   
                switch (dataStore)
                {
                    case "SQLServer":
                        return "datetime2";
                    case "PostgreSQL":
                        return "timestamp";
                    default:
                        throw new ArgumentException($"Invalid data store: {dataStore}");
                }
            } 
        }
    }

    public partial class InitialCreate
    {
       
        public string IdTypeName 
        { 
            get { return DataHelper.IdTypeName; } 
        }

        public string BoolTypeName 
        { 
            get { return DataHelper.BoolTypeName;}
        }
        

        public string StringTypeName
        {
            get { return DataHelper.StringTypeName; }
        }

        public string DateTimeTypeName
        {
            get { return DataHelper.DateTimeTypeName; }
        }
   }

   public partial class ListenTogetherDbContextModelSnapshot
   {

        public string IdTypeName
        { 
            get { return DataHelper.IdTypeName; } 
        }

        public string BoolTypeName 
        { 
            get { return DataHelper.BoolTypeName;}
        }

        public string StringTypeName
        {
            get { return DataHelper.StringTypeName; }
        }

        public string DateTimeTypeName
        {
            get { return DataHelper.DateTimeTypeName; }
        }
   }
}