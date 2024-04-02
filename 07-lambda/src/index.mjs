export const handler = async () => {
    const response = {
        statusCode: 200,
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            message: "Hello User Group!"
        }),
    };
    return response;
};
