module.exports = {
  testEnvironment: "node",
  testMatch: ["**/__tests__/**/*.test.ts"],
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      {
        tsconfig: {
          // Relax unused-locals check so test helpers don't fail tsc inside ts-jest
          noUnusedLocals: false,
          // Ensure global test typings resolve under module: NodeNext
          types: ["jest", "node"],
          isolatedModules: true,
        },
      },
    ],
  },
};
