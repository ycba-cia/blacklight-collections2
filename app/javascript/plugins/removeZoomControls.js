import React, { Component } from 'react';

// a plugin to remove default navigation controls
class RemoveNavPlugin2 extends Component {

    render() {
        return (
            <div>
            </div>
    );
    }
}

export default {
    component: RemoveNavPlugin2,
    target: 'ZoomControls',
    mode: 'wrap',
};