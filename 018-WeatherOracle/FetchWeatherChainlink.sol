// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {FunctionsClient} from "@chainlink/contracts@1.5.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";

import {FunctionsRequest} from "@chainlink/contracts@1.5.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.5.0/src/v0.8/shared/access/ConfirmedOwner.sol";

contract FetchWeatherChainlink is FunctionsClient, ConfirmedOwner {

    using FunctionsRequest for FunctionsRequest.Request;

    address private router;
    bytes32 private donId;

    uint32 constant GAS_LIMIT = 300_000; // gas limit

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // State variable to store the returned character information
    string private weatherDetails;
    
    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event WeatherDetailsResponse(bytes32 indexed requestId, string weatherDetails, bytes response, bytes err);

    constructor(
        address _router,
        bytes32 _donId
    ) FunctionsClient(_router) ConfirmedOwner(msg.sender) {
        router = _router;
        donId = _donId;
    }

    function getWeatherDetails() public view returns(string memory) {
        return weatherDetails;
    }
    function getRouterAddr() public view returns (address) {
        return router;
    }
    function getDonID() public view returns (bytes32) {
        return donId;
    }

    // my source string
    string private constant SOURCE =
    "const cityName = args[0].trim();"
    "const apiKey = args[1].trim();"
    "const url = `https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/${encodeURIComponent(cityName)}/today?unitGroup=metric&include=current&key=${apiKey}&contentType=flatjson`;"
    "console.log('Request URL:', url);"
    "const apiResponse = await Functions.makeHttpRequest({ url });"
    "if (apiResponse.error) {"
    "  console.error('API Error:', apiResponse.error);"
    "  throw Error('Request failed');"
    "}"
    "const data = apiResponse.data;"
    "if (!data || !data.currentConditions) {"
    "  throw Error('Invalid API response');"
    "}"
    "const cc = data.currentConditions;"
    "const retData = ["
    "  `epoch:${cc.datetimeEpoch ?? 0}`,"
    "  `temp:${cc.temp ?? 0}`,"
    "  `humidity:${cc.humidity ?? 0}`,"
    "  `precip:${cc.precip ?? 0}`,"
    "  `snow:${cc.snow ?? 0}`,"
    "  `windspeed:${cc.windspeed ?? 0}`,"
    "  `uvindex:${cc.uvindex ?? 0}`,"
    "  `cloudcover:${cc.cloudcover ?? 0}`"
    "].join(';') + ';';"
    "return Functions.encodeString(retData);";

    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args
    ) external onlyOwner returns (bytes32 requestId) {

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE); // Initialize the request with JS code
        require(args.length > 0, "Missing characterId");
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, GAS_LIMIT, donId);

        return s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }

        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        weatherDetails = string(response);
        s_lastError = err;

        // Emit an event to log the response
        emit WeatherDetailsResponse(requestId, weatherDetails, s_lastResponse, s_lastError);
    }
}