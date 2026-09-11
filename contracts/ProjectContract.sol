// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ProjectContract {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "ReentracyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    enum Status {
        Pending,
        Active,
        Completed,
        Cancelled
    }
    struct Project {
        uint256 projectId;
        string title;
        string description;
        uint256 budget;
        uint256 deadline;
        address payable owner;
        address freelancer;
        Status currentStatus;
        bool isWorkSubmited;
    }

    uint256 public projectCount;

    mapping(uint256 => Project) public projects;
    mapping(address => uint256[]) private _clientProjects;
    mapping(address => uint256[]) private _freelancerProjects;
    mapping(address => mapping(uint256 => uint256)) public freelancerBids;

    event CreateProject(
        uint256 indexed projectCount,
        address indexed owner,
        uint256 budget
    );
    event ProjectBid(uint256 indexed projectId, address freelancer);
    event FreelancerAssigned(
        uint256 indexed projectId,
        address indexed freelancer
    );
    event WorkSubmitted(
        uint256 indexed projectId,
        address indexed freelancer,
        uint256 timestamp
    );
    event PaymentReleased(
        uint256 indexed projectId,
        address indexed freelancer,
        uint256 amount
    );

    modifier checkProjectExist(uint256 _projectId) {
        require(
            projects[_projectId].owner != address(0),
            "Project does not exist."
        );
        _;
    }

    function createProject(
        string memory _title,
        string memory _description,
        uint256 _deadline
    ) public payable returns (uint256) {
        require(msg.value > 0, "Budget must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        projectCount++;

        projects[projectCount] = Project({
            projectId: projectCount,
            title: _title,
            description: _description,
            budget: msg.value,
            deadline: _deadline,
            owner: payable(msg.sender),
            freelancer: address(0),
            currentStatus: Status.Pending,
            isWorkSubmited: false
        });

        _clientProjects[msg.sender].push(projectCount);
        emit CreateProject(projectCount, msg.sender, msg.value);
        return projectCount;
    }

    function submitBid(
        uint256 _projectId,
        uint256 _bidAmount
    ) public checkProjectExist(_projectId) {
        require(
            projects[_projectId].currentStatus == Status.Pending,
            "Project is not accepting bids."
        );
        require(
            _bidAmount <= projects[_projectId].budget,
            "Bid cannot exceed client budget"
        );

        freelancerBids[msg.sender][_projectId] = _bidAmount;
        emit ProjectBid(_projectId, msg.sender);
    }

    function assignFreelancer(
        uint256 _projectId,
        address _freelancer
    ) public checkProjectExist(_projectId) {
        Project storage project = projects[_projectId];
        require(
            project.owner == msg.sender,
            "Only project owner can assign freelancer"
        );
        require(
            project.currentStatus == Status.Pending,
            "Project is already active or closed"
        );
        require(
            freelancerBids[_freelancer][_projectId] > 0,
            "Freelancer has not bid on this project"
        );

        project.freelancer = _freelancer;
        project.currentStatus = Status.Active;

        _freelancerProjects[_freelancer].push(_projectId);
        emit FreelancerAssigned(_projectId, _freelancer);
    }

    function submitWork(uint256 _projectId) public checkProjectExist(_projectId) {
        Project storage project = projects[_projectId];

        require(
            project.freelancer == msg.sender,
            "Only assigned freelancer can submit work"
        );
        require(
            project.currentStatus == Status.Active,
            "Project is not active"
        );
        require(block.timestamp <= project.deadline, "Deadline has passed");

        project.isWorkSubmited = true;
        emit WorkSubmitted(_projectId, msg.sender, block.timestamp);
    }

    function releasePayment(
        uint256 _projectId
    ) public checkProjectExist(_projectId) nonReentrant {
        Project storage project = projects[_projectId];

        require(
            project.owner == msg.sender,
            "Only project owner can release payment"
        );
        require(
            project.currentStatus == Status.Active,
            "Project is not active"
        );
        require(project.isWorkSubmited, "Work has not been submitted yet");

        uint256 freelancerPayout = freelancerBids[project.freelancer][_projectId];
        uint256 clientRefund = project.budget - freelancerPayout;
        project.currentStatus = Status.Completed;

        (bool success1, ) = payable(project.freelancer).call{
            value: freelancerPayout
        }("");
        require(success1, "Freelancer transfer failed");
        if (clientRefund > 0) {
            (bool success2, ) = project.owner.call{value: clientRefund}("");
            require(success2, "Client refund failed");
        }
        emit PaymentReleased(_projectId, project.freelancer, freelancerPayout);
    }

    function getClientProjects(
        address _client
    ) public view returns (uint256[] memory) {
        return _clientProjects[_client];
    }

    function getFreelancerProjects(
        address _freelancer
    ) public view returns (uint256[] memory) {
        return _freelancerProjects[_freelancer];
    }
}
