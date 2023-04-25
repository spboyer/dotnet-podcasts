using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Podcast.Infrastructure.Data.Migrations
{
    public partial class feedapproval : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserSubmittedFeeds",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: IdTypeName, nullable: false),
                    Url = table.Column<string>(type: StringTypeName, nullable: false),
                    Title = table.Column<string>(type: StringTypeName, nullable: false),
                    Timestamp = table.Column<DateTime>(type: DateTimeTypeName, nullable: false),
                    Categories = table.Column<string>(type: StringTypeName, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserSubmittedFeeds", x => x.Id);
                });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserSubmittedFeeds");
        }
    }
}
