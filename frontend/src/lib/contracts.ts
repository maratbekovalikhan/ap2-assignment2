export type ContractAddressBook = {
  governor: string;
  timelock: string;
  governanceToken: string;
  craftingStation: string;
  itemsProxy: string;
  rentalVault: string;
  revenueVault: string;
  resourceFactory: string;
};

export const contractAddresses: ContractAddressBook = {
  governor: import.meta.env.VITE_GOVERNOR_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  timelock: import.meta.env.VITE_TIMELOCK_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  governanceToken: import.meta.env.VITE_GOV_TOKEN_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  craftingStation: import.meta.env.VITE_CRAFTING_STATION_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  itemsProxy: import.meta.env.VITE_ITEMS_PROXY_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  rentalVault: import.meta.env.VITE_RENTAL_VAULT_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  revenueVault: import.meta.env.VITE_REVENUE_VAULT_ADDRESS ?? "0x0000000000000000000000000000000000000000",
  resourceFactory: import.meta.env.VITE_RESOURCE_FACTORY_ADDRESS ?? "0x0000000000000000000000000000000000000000",
};

export const targetNetwork = import.meta.env.VITE_TARGET_NETWORK ?? "Base Sepolia";
