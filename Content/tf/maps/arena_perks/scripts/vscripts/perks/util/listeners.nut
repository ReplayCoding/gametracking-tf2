//=========================================================================
//Copyright LizardOfOz, with modifications.
//=========================================================================

listeners <- {}

//The higher the value the LATER it will execute
::AddListener <- function(event, listener, order=1)
{
    local listener_object = [order, listener];

    // No listeners yet
    if (!(event in listeners)) listeners[event] <- [];

    // Try to slot the listener right before other listeners with higher order
    for (local i = 0; i < listeners[event].len(); i ++) {
        local obj = listeners[event][i];
        if (obj[0] > order) {
            listeners[event].insert(listener_object, i);
            return;
        }
    }

    // If we fail to do that, it means all other orders are equal to or lesser than the input
    // Just put it at the end of the list
    listeners[event].push(listener_object);
    // listeners[event].sort(@(it, that) it[0] - that[0]);
}

::FireListeners <- function(event, params=null)
{
    if (!(event in listeners))
        return;

    foreach (entry in listeners[event])
        try
            entry[1].call(this, params)
        catch (e)
            printl(e)
}