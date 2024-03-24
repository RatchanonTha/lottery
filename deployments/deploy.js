async function main() {
    const lottery = await ethers.getContractFactory("lottery");
    const Lottery = await lottery.deploy(60,60,60,2);
    console.log("Contract Deployed to Address:", Lottery.address);
  }
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });