// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract CrowdfundingPlatform {
    
    struct Campaign {
        address payable creator;
        string description;
        uint goal;
        uint deadline;
        uint raisedAmount;
        uint currentMilestone;
        uint totalMilestones;
        bool fundsReleased;
        bool isCompleted;
        mapping(address => uint) contributions;
        Milestone[] milestones;
    }

    struct Milestone {
        string description;
        uint amountToRelease;
        bool isReached;
    }

    uint public totalCampaigns;
    mapping(uint => Campaign) public campaigns;

    event CampaignCreated(uint indexed campaignId, address indexed creator, string description, uint goal, uint deadline);
    event ContributionMade(uint indexed campaignId, address indexed contributor, uint amount);
    event MilestoneReached(uint indexed campaignId, uint milestoneIndex);
    event FundsReleased(uint indexed campaignId, uint amount);

    function createCampaign(string memory _description, uint _goal, uint _deadline, string[] memory _milestoneDescriptions, uint[] memory _milestoneAmounts) external {
        require(_goal > 0, "Goal must be greater than zero");
        require(_deadline > block.timestamp, "Deadline should be in the future");
        require(_milestoneDescriptions.length == _milestoneAmounts.length, "Milestone descriptions and amounts must match");

        totalCampaigns++;
        Campaign storage newCampaign = campaigns[totalCampaigns];
        newCampaign.creator = payable(msg.sender);
        newCampaign.description = _description;
        newCampaign.goal = _goal;
        newCampaign.deadline = _deadline;
        newCampaign.totalMilestones = _milestoneDescriptions.length;

        for (uint i = 0; i < _milestoneDescriptions.length; i++) {
            newCampaign.milestones.push(Milestone({
                description: _milestoneDescriptions[i],
                amountToRelease: _milestoneAmounts[i],
                isReached: false
            }));
        }

        emit CampaignCreated(totalCampaigns, msg.sender, _description, _goal, _deadline);
    }

    function contribute(uint _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has expired");
        require(msg.value > 0, "Contribution must be greater than zero");
        require(campaign.raisedAmount < campaign.goal, "Campaign has already reached its goal");
        
        campaign.raisedAmount += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    function releaseFunds(uint _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only the campaign creator can release funds");
        require(!campaign.isCompleted, "Campaign is already completed");
        require(campaign.raisedAmount >= campaign.goal, "Campaign has not reached its goal");

        Milestone storage milestone = campaign.milestones[campaign.currentMilestone];
        require(!milestone.isReached, "Milestone already reached");

        campaign.creator.transfer(milestone.amountToRelease);
        milestone.isReached = true;
        campaign.currentMilestone++;

        emit MilestoneReached(_campaignId, campaign.currentMilestone);
        emit FundsReleased(_campaignId, milestone.amountToRelease);

        if (campaign.currentMilestone == campaign.totalMilestones) {
            campaign.isCompleted = true;
        }
    }

    function getCampaignDetails(uint _campaignId) external view returns (
        address creator, string memory description, uint goal, uint deadline, uint raisedAmount, uint currentMilestone, uint totalMilestones, bool isCompleted
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.description,
            campaign.goal,
            campaign.deadline,
            campaign.raisedAmount,
            campaign.currentMilestone,
            campaign.totalMilestones,
            campaign.isCompleted
        );
    }

    function getMilestoneDetails(uint _campaignId, uint _milestoneIndex) external view returns (string memory description, uint amountToRelease, bool isReached) {
        Campaign storage campaign = campaigns[_campaignId];
        Milestone storage milestone = campaign.milestones[_milestoneIndex];
        return (milestone.description, milestone.amountToRelease, milestone.isReached);
    }
}
