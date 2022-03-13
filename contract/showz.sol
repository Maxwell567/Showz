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

  // mapping the Drug struct internally
  mapping (uint => Showcase) internal showcase;

  //Event that emits when a specific function is executed.
  event likedShowcase(uint index, address indexed user, string action);
  event dislikedShowcase(uint index, address indexed user, string action);

  // add showcase
  function addShowcases(
    string memory _name,
    string memory _image,
    string memory _description

  ) public {
    uint _likes = 0;
    uint _dislikes = 0;
    showcase[showcaseLength] = Showcase(
        payable(msg.sender),
        _name,
        _image,
        _description,
        _likes,
        _dislikes
    );
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
  function likeShowcase(uint _index) public {     
    showcase[_index].likes = showcase[_index].likes.add(1);
    emit likedShowcase(_index, msg.sender, "Liked showcase");
  }

  // anyone can dislike a showcase
  function dislikeShowcase(uint _index) external {
    showcase[_index].dislikes = showcase[_index].dislikes.add(1);
    emit dislikedShowcase(_index, msg.sender, "Disliked showcase!");
  }
  
  // get the length of showcase
  function getShowcaseLength() public view returns (uint) {
    return (showcaseLength);
  }
}