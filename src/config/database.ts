import { DataSource } from "typeorm";
import "reflect-metadata";

export const AppDataSource = new DataSource({
  type: "mssql",
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "1433"),
  username: process.env.DB_USERNAME || "sa",
  password: process.env.DB_PASSWORD || "YourStrong@Passw0rd",
  database: process.env.DB_NAME || "master",
  options: {
    encrypt: true,
    trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === "true",
  },
  synchronize: false,
  logging: true,
});
