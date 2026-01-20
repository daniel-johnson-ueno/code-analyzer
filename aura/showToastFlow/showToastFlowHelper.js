({
    showToast: function(type, message, title, duration, mode) {
        var toastEvent = $A.get("e.force:showToast");
        var params = {
            "message": message,
            "type": type,
            "duration": duration,
            "mode": mode
        };
        
        // 🔹 Only set the title if it exists
        if (title && title.trim() !== "") {
            params.title = title;
        }

        toastEvent.setParams(params);
        toastEvent.fire();
    }
})