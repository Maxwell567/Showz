// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// import openzeppelin
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Showz {
  // showcase struct
  struct Showcase {
    address payable owner;
    string name;
    string image;
    string description;
    uint likes;
    uint dislikes;
    uint numOfFeedbacks;
    uint totalAmountDonated;
    mapping(address => bool) hasLiked;
    mapping(uint => Feedback) feedbacks;
    mapping(address => bool) hasDisliked;
    mapping(address => uint ) donatedAmount;
  }

  struct Feedback{
    string feedback;
    address poster;
  }

  // setting cUSD token address
  address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

  // showcase length
  uint public showcaseLength = 0;

  // using safemath in our contract
  using SafeMath for uint;

  // like and dislike price 1 cusd
  uint likeAndDislikePrice = 1e18;

  // admin address
  address _adminContractAddress;

  // admin address constructor
  constructor(address payable _admin){
    _adminContractAddress = _admin;
  }

  // checking if admin
  modifier isAdmin() {
    require(msg.sender == _adminContractAddress, "Only the admin can access this");
    _;
  }

  modifier notTheOwner(uint _index){
    require(msg.sender != showcase[_index].owner, "You cannot access this functionality for your own showcase");
    _;
  }

  // mapping the Drug struct internally
  mapping (uint => Showcase) internal showcase;


  //Event that emits when a specific function is executed.
  event likedShowcase(uint index, address indexed user, string action);
  event dislikedShowcase(uint index, address indexed user, string action);
  event newDonation(address indexed owner, uint amount, address indexed donator);
  event newShowcase(address indexed owner, uint index);

  // add showcase
  function addShowcases(
    string memory _name,
    string memory _image,
    string memory _description

  ) public {
    Showcase storage show = showcase[showcaseLength];
    show.owner = payable(msg.sender);
    show.description = _description;
    show.name = _name;
    show.image = _image;
    show.numOfFeedbacks = 0;

    emit newShowcase(msg.sender, showcaseLength);
    showcaseLength++;
  }

  // get showcases
  function getShowcases(uint _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    uint, 
    uint
  ) {
    return (
      showcase[_index].owner,
      showcase[_index].name,
      showcase[_index].image,
      showcase[_index].description,
      showcase[_index].likes,
      showcase[_index].dislikes
    );
  }

  // anyone can like a showcase
  function likeShowcase(uint _index) external notTheOwner(_index){ 
    //Has a modifier that makes prevents the poster from liking his own showCase

    //Require statements that prevents users from disliking the showCase multiple times
    require(showcase[_index].hasLiked[msg.sender] == false, "You can like the showCase only once");

    //Increases the number of likes by one and set the address to be true so that the address can't like again
    showcase[_index].likes = showcase[_index].likes.add(1);
    emit likedShowcase(_index, msg.sender, "Liked showcase");
    showcase[_index].hasLiked[msg.sender] = true;

    //If the address has liked also, the like will be undone
    if(showcase[_index].hasDisliked[msg.sender] == true){
      showcase[_index].dislikes = showcase[_index].dislikes.sub(1);
      showcase[_index].hasDisliked[msg.sender] = false;
    }
  }

  // anyone can dislike a showcase
  function dislikeShowcase(uint _index) external notTheOwner(_index){
    //Has modifier that makes prevents the poster from disliking his own showCase

    //Require statements that prevents users from disliking the showCase multiple times
    require(showcase[_index].hasDisliked[msg.sender] == false, "You can dislike the showCase only once");

    //Increases the number of dislikes by one and set the address to be true so that the address can't dislike again
    showcase[_index].dislikes = showcase[_index].dislikes.add(1);
    emit dislikedShowcase(_index, msg.sender, "Disliked showcase!");
    showcase[_index].hasDisliked[msg.sender] = true;
    
    //If the address has liked also, the like will be undone
    if(showcase[_index].hasLiked[msg.sender] == true){
      showcase[_index].likes = showcase[_index].likes.sub(1);
      showcase[_index].hasLiked[msg.sender] = false;
    }
  }

  //A function where the user can also give a verbal feedback to the showCase
  function giveFeedback(uint _showindex, string memory _feedback) public{
    Showcase storage showCase = showcase[_showindex];
    uint FeedbackIndex = showCase.numOfFeedbacks;
    showCase.feedbacks[FeedbackIndex] = Feedback(
      _feedback,
      msg.sender
    );
    showCase.numOfFeedbacks++;

  }

  //Function to view Feedbacks

  function getFeedbacks(uint _showCaseIndex, uint _feedBackIndex) public view returns(
    string memory feedback, 
    address poster
  ){
    return (
      showcase[_showCaseIndex].feedbacks[_feedBackIndex].feedback,
      showcase[_showCaseIndex].feedbacks[_feedBackIndex].poster
    );
  }

    //Function using which the users can donate money to the showcase they like to support
  function donateMoneyToTheShowcase(uint _index, uint _amount) public notTheOwner(_index){
    require(
        IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender, 
        showcase[_index].owner, 
        _amount
        ),
        "Transfer failed"
    );

    showcase[_index].donatedAmount[msg.sender] += _amount;

    emit newDonation(showcase[_index].owner,_amount, msg.sender );
  }

  
  // get the length of showcase
  function getShowcaseLength() public view returns (uint) {
    return (showcaseLength);
  }

    //Function to get the total number of feedbacks for a particular showcase
  function getFeedbacksLength(uint _index) public view returns(uint){
    return showcase[_index].numOfFeedbacks;
  }
}