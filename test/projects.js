import { expect } from "chai";
import hre from "hardhat";

const { ethers, networkHelpers } = await hre.network.create();

describe("ProjectContract", function () {
  let projectContract;
  let client, freelancer, otherUser;
  let deadline;

  beforeEach(async function () {
    [client, freelancer, otherUser] = await ethers.getSigners();
    const ProjectContract = await ethers.getContractFactory("ProjectContract");

    projectContract = await ProjectContract.deploy();

    const latestBlock = await ethers.provider.getBlock("latest");
    deadline = latestBlock?.timestamp + 7 * 24 * 60 * 60; // next 7 days
  });

  describe("Project creation", function () {
    const budget = ethers.parseEther("1.0");
    const title = "Fix Website";
    const description = "Fix UI bugs";

    it("Should successfully create a project with escrow budget", async function () {
      await expect(
        projectContract
          .connect(client)
          .createProject(title, description, deadline, {
            value: budget,
          }),
      )
        .to.emit(projectContract, "CreateProject")
        .withArgs(1, client.address, budget);

      const project = await projectContract.projects(1);
      expect(project.title).to.equal(title);
      expect(project.budget).to.equal(budget);
      expect(project.currentStatus).to.equal(0);
    });

    it("should revert if budget is 0", async function () {
      expect(
        projectContract
          .connect(client)
          .createProject(title, description, deadline, { value: 0 }),
      ).to.be.revertedWith("Budget must be greater than 0");
    });
    it("should revert if deadline is passed", function () {
      expect(
        projectContract
          .connect(client)
          .createProject(title, description, 1789104604, {
            value: budget,
          }),
      ).to.be.revertedWith("Deadline must be in the future.");
    });
  });

  describe("Bidding System", function () {
    const title = "Fix Website";
    const description = "Fix UI bugs";

    beforeEach(async function () {
      await projectContract
        .connect(client)
        .createProject(title, description, deadline, {
          value: ethers.parseEther("1.0"),
        });
    });

    it("Should allow freelancers to submit a bid within budget", async function () {
      const bidAmount = ethers.parseEther("0.8");

      await expect(projectContract.connect(freelancer).submitBid(1, bidAmount))
        .to.emit(projectContract, "ProjectBid")
        .withArgs(1, freelancer.address);

      const storedBid = await projectContract.freelancerBids(
        freelancer.address,
        1,
      );
      expect(storedBid).to.equal(bidAmount);
    });
    
    it("Should revert if bid exceeds project budget", async function () {
      const highBid = ethers.parseEther("1.2"); // বাজেটের চেয়ে বেশি বিড
      await expect(
        projectContract.connect(freelancer).submitBid(1, highBid),
      ).to.be.revertedWith("Bid cannot exceed client budget");
    });
  });
});
