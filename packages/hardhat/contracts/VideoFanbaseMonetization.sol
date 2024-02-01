// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VideoFanbaseMonetization is Ownable {
    // Structure to hold video details
    struct Video {
        string title;
        string contentUrl;
        uint256 price; // Price in tokens to access the video
        address uploader;
        bool exists;
    }

    // Mapping from video ID to Video struct
    mapping(uint256 => Video) public videos;
    // Mapping from viewer to the list of video IDs they have access to
    mapping(address => uint256[]) public accessList;

    // The token used for purchases
    IERC20 public paymentToken;

    // Event emitted when a new video is uploaded
    event VideoUploaded(uint256 indexed videoId, string title, string contentUrl, uint256 price, address uploader);
    // Event emitted when a video is purchased
    event VideoPurchased(uint256 indexed videoId, address indexed buyer);

    /**
     * @param _paymentTokenAddress The address of the ERC20 token to be used for payments.
     */
    constructor(address _paymentTokenAddress) {
        require(_paymentTokenAddress != address(0), "Invalid token address");
        paymentToken = IERC20(_paymentTokenAddress);
    }

    /**
     * @notice Allows a user to upload a video to the platform.
     * @param _videoId The ID for the video being uploaded.
     * @param _title The title of the video.
     * @param _contentUrl The URL where the video content is hosted.
     * @param _price The price for accessing the video.
     */
    function uploadVideo(uint256 _videoId, string memory _title, string memory _contentUrl, uint256 _price) external {
        require(!videos[_videoId].exists, "Video already exists");
        videos[_videoId] = Video({
            title: _title,
            contentUrl: _contentUrl,
            price: _price,
            uploader: msg.sender,
            exists: true
        });
        emit VideoUploaded(_videoId, _title, _contentUrl, _price, msg.sender);
    }

    /**
     * @notice Allows a user to purchase access to a video.
     * @param _videoId The ID of the video to purchase.
     */
    function purchaseVideo(uint256 _videoId) external {
        require(videos[_videoId].exists, "Video does not exist");
        Video memory video = videos[_videoId];
        require(paymentToken.transferFrom(msg.sender, video.uploader, video.price), "Payment failed");
        accessList[msg.sender].push(_videoId);
        emit VideoPurchased(_videoId, msg.sender);
    }

    /**
     * @notice Checks if a user has access to a given video.
     * @param _user The address of the user.
     * @param _videoId The ID of the video.
     * @return true if the user has purchased access to the video, otherwise false.
     */
    function hasAccessToVideo(address _user, uint256 _videoId) public view returns (bool) {
        uint256[] memory userVideos = accessList[_user];
        for (uint256 i = 0; i < userVideos.length; i++) {
            if(userVideos[i] == _videoId) {
                return true;
            }
        }
        return false;
    }
}