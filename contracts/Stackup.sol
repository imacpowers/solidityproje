// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuestContract {
    enum PlayerQuestStatus {
        NOT_JOINED,
        JOINED,
        SUBMITTED,
        REJECTED,
        APPROVED,
        REWARDED,
        NOT_SUBMITTED
    }

    struct Quest {
        uint256 questId;
        uint256 numberOfPlayers;
        string title;
        uint8 reward;
        uint256 numberOfRewards;
        uint256 startDate;
        uint256 endDate;
        PlayerQuestStatus status;
    }

    struct Campaign {
        uint256 campaignId;
        string topic;
        uint256[] questIds;
    }

    address public admin;
    uint256 public nextQuestId;
    uint256 public nextCampaignId;
    mapping(uint256 => Quest) public quests;
    mapping(address => mapping(uint256 => PlayerQuestStatus)) public playerQuestStatuses;
    mapping(uint256 => Campaign) public campaigns;

    constructor() {
        admin = msg.sender;
    }

    function createQuest(
        string calldata title_,
        uint8 reward_,
        uint256 numberOfRewards_,
        uint256 startDate_,
        uint256 endDate_,
        uint256 campaignId_
    ) external onlyAdmin {
        quests[nextQuestId] = Quest({
            questId: nextQuestId,
            numberOfPlayers: 0,
            title: title_,
            reward: reward_,
            numberOfRewards: numberOfRewards_,
            startDate: startDate_,
            endDate: endDate_,
            status: PlayerQuestStatus.NOT_JOINED
        });

        campaigns[campaignId_].questIds.push(nextQuestId);
        nextQuestId++;
    }

    function editQuest(
        uint256 questId,
        string calldata title_,
        uint8 reward_,
        uint256 numberOfRewards_,
        uint256 startDate_,
        uint256 endDate_
    ) external onlyAdmin questExists(questId) {
        quests[questId].title = title_;
        quests[questId].reward = reward_;
        quests[questId].numberOfRewards = numberOfRewards_;
        quests[questId].startDate = startDate_;
        quests[questId].endDate = endDate_;
    }

    function deleteQuest(uint256 questId) external onlyAdmin questExists(questId) {

        delete quests[questId];
    }

    function createCampaign(string calldata topic_) external onlyAdmin {
        campaigns[nextCampaignId] = Campaign({
            campaignId: nextCampaignId,
            topic: topic_,
            questIds: new uint256[](0)
        });

        nextCampaignId++;
    }

    function assignQuestToCampaign(uint256 questId, uint256 campaignId) external onlyAdmin questExists(questId) campaignExists(campaignId) {
        
        campaigns[campaignId].questIds.push(questId);
    }
    function deleteCampaign(uint256 campaignId) external onlyAdmin campaignExists(campaignId) {

        delete campaigns[campaignId];
    }

    function joinQuest(uint256 questId) external questExists(questId) {
        require(
            playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.NOT_JOINED,
            "Player has already joined/submitted this quest"
        );

        require(block.timestamp >= quests[questId].startDate, "Quest has not started yet");
        require(block.timestamp <= quests[questId].endDate, "Quest has already ended");

        playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.JOINED;
        quests[questId].numberOfPlayers++;
    }

  function submitQuest(uint256 questId) external questExists(questId) {
    if (playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.JOINED) {
        require(block.timestamp > quests[questId].endDate, "Quest has not ended yet");
        playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.NOT_SUBMITTED;
        require(block.timestamp < quests[questId].endDate, "Quest has ended");
        playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.SUBMITTED;
    } else if (playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.NOT_JOINED) {
        require(block.timestamp > quests[questId].endDate, "Quest has not ended yet");
        playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.NOT_JOINED;
    }
}


    function reviewQuestSubmission(uint256 questId, address player, bool isSubmissionCorrect) external onlyAdmin questExists(questId) {
        require(
            playerQuestStatuses[player][questId] == PlayerQuestStatus.SUBMITTED,
            "Player submission not found"
        );

        if (isSubmissionCorrect) {
            if (quests[questId].numberOfRewards == 0) {
                playerQuestStatuses[player][questId] = PlayerQuestStatus.APPROVED;
            } else {
                playerQuestStatuses[player][questId] = PlayerQuestStatus.REWARDED;
                quests[questId].numberOfRewards++;
            }
        } else {
            playerQuestStatuses[player][questId] = PlayerQuestStatus.REJECTED;
        }
    }

    modifier questExists(uint256 questId) {
        require(questId < nextQuestId, "Quest does not exist");
        _;
    }

   

    modifier campaignExists(uint256 campaignId) {
        require(campaignId < nextCampaignId, "Campaign does not exist");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }
}
