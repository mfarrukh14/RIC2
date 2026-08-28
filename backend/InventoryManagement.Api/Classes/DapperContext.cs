using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Classes
{
    public class DapperContext
    {
        private readonly string _connectionString;

        public DapperContext(string ConnectionString)
        {
            _connectionString = ConnectionString;
        }
        public IDbConnection CreateConnection()
            => new SqlConnection(_connectionString);
    }
}
