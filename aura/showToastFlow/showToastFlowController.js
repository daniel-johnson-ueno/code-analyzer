({
    invoke: function(component, event, helper) {
        var message = component.get("v.messageText");
        var title = component.get("v.title");
        var type = component.get("v.type");
        var duration = component.get("v.duration");
        var mode = component.get("v.mode");

        // Ensure message has content — fallback to title if necessary
        if (!message || message.trim() === "") {
            message = title || ""; // Use title as message if messageText is empty
            title = null; // Avoid showing title twice
        }

        helper.showToast(type, message, title, duration, mode);
    }
});