enum Flavor { dev, staging, prod }

Flavor flavorFromString(String value) {
  switch (value) {
    case 'dev':
      return Flavor.dev;
    case 'staging':
      return Flavor.staging;
    case 'prod':
      return Flavor.prod;
    default:
      return Flavor.dev;
  }
}
