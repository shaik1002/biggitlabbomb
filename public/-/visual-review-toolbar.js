///////////////////////////////////////////////
/////////////////// STYLES ////////////////////
///////////////////////////////////////////////

const buttonClearStyles = `
  -webkit-appearance: none;
`;

const buttonBaseStyles = `
  cursor: pointer;
`;

const buttonSuccessStyles = `
  ${buttonBaseStyles}
  background-color: #1aaa55;
  border-color: #168f48;
  color: #fff;
`

const buttonWideStyles = `
  ${buttonSuccessStyles}
  width: 100%;
`

const buttonSecondaryStyles = `
  ${buttonBaseStyles}
  background: none #fff;
  margin: 0 .5rem;
`;

const buttonWrapperStyles = `
  margin-top: 1rem;
  display: flex;
  align-items: baseline;
  justify-content: flex-end;
`;

const collapseStyles = `
  ${buttonBaseStyles}
  width: 2.4rem;
  height: 2.2rem;
  margin-right: 1rem;
  padding: .5rem;
`;

const collapseClosedStyles = `
  ${collapseStyles}
  align-self: center;
`;

const collapseOpenStyles = `
  ${collapseStyles}
`;

const checkboxLabelStyles = `
  padding: 0 .2rem;
`;

const checkboxWrapperStyles = `
  display: flex;
  align-items: baseline;
`;

const formStyles = `
  display: flex;
  flex-direction: column;
  width: 100%
`;

const labelStyles = `
  font-weight: 600;
  display: inline-block;
  width: 100%;
`;

const linkStyles = `
  color: #1b69b6;
  text-decoration: none;
  background-color: transparent;
  background-image: none;
`;

const messageStyles =  `
  padding: .25rem 0;
  margin: 0;
  line-height: 1.2rem;
`;

const metadataNoteStyles = `
  font-size: .7rem;
  line-height: 1rem;
  color: #666;
  margin-bottom: 0;
`;

const inputStyles = `
  width: 100%;
  border: 1px solid #dfdfdf;
  border-radius: 4px;
  padding: .1rem .2rem;
`;

const wrapperClosedStyles = `
  max-width: 3.4rem;
  max-height: 3.4rem;
`;

const wrapperOpenStyles = `
  max-width: 22rem;
  max-height: 22rem;
`;

const wrapperStyles = `
  transition: all 200ms;
  max-width: 22rem;
  max-height: 22rem;
  overflow: scroll;
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  display: flex;
  padding: 1rem;
  background-color: #fff;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen-Sans, Ubuntu, Cantarell,
  'Helvetica Neue', sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol',
  'Noto Color Emoji';
  font-size: .8rem;
  font-weight: 400;
  color: #2e2e2e;
`;

const gitlabStyles = `
  #gitlab-form-wrapper {
    ${formStyles}
  }

  #gitlab-review-container {
    ${wrapperStyles}
  }

  .gitlab-open-wrapper {
    ${wrapperOpenStyles}
  }

  .gitlab-closed-wrapper {
    ${wrapperClosedStyles}
  }

  .gitlab-button-secondary {
    ${buttonSecondaryStyles}
  }

  .gitlab-button-success {
    ${buttonSuccessStyles}
  }

  .gitlab-button-wide {
    ${buttonWideStyles}
  }

  .gitlab-button-wrapper {
    ${buttonWrapperStyles}
  }

  .gitlab-collapse-closed {
    ${collapseClosedStyles}
  }

  .gitlab-collapse-open {
    ${collapseOpenStyles}
  }

  .gitlab-checkbox-label {
    ${checkboxLabelStyles}
  }

  .gitlab-checkbox-wrapper {
    ${checkboxWrapperStyles}
  }

  .gitlab-label {
    ${labelStyles}
  }

  .gitlab-link {
    ${linkStyles}
  }

  .gitlab-message {
    ${messageStyles}
  }

  .gitlab-metadata-note {
    ${metadataNoteStyles}
  }

  .gitlab-input {
    ${inputStyles}
  }
`;

function addStylesheet() {
  const styleEl = document.createElement('style');
  styleEl.insertAdjacentHTML('beforeend', gitlabStyles);
  document.head.appendChild(styleEl);
}

///////////////////////////////////////////////
/////////////////// STATE ////////////////////
///////////////////////////////////////////////
const data = {};

///////////////////////////////////////////////
///////////////// COMPONENTS //////////////////
///////////////////////////////////////////////
const note = `
  <p id='gitlab-validation-note' class='gitlab-message'></p>
`;

const comment = `
  <div>
    <textarea id='gitlab-comment' name='gitlab-comment' rows='3' placeholder='Enter your feedback or idea' class='gitlab-input'></textarea>
    ${note}
    <p class='gitlab-metadata-note'>Additional metadata will be included: browser, OS, current page, user agent, and viewport dimensions.</p>
  </div>
  <div class='gitlab-button-wrapper''>
    <button class='gitlab-button-secondary' style='${buttonClearStyles}' type='button' id='gitlab-logout-button'> Logout </button>
    <button class='gitlab-button-success' style='${buttonClearStyles}' type='button' id='gitlab-comment-button'> Send feedback </button>
  </div>
`;

const commentIcon = `
  <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icn/comment</title><path d="M4 11.132l1.446-.964A1 1 0 0 1 6 10h5a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v6.132zM6.303 12l-2.748 1.832A1 1 0 0 1 2 13V5a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3v4a3 3 0 0 1-3 3H6.303z" id="a"/></svg>
`

const compressIcon = `
  <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icn/compress</title><path d="M5.27 12.182l-1.562 1.561a1 1 0 0 1-1.414 0h-.001a1 1 0 0 1 0-1.415l1.56-1.56L2.44 9.353a.5.5 0 0 1 .353-.854H7.09a.5.5 0 0 1 .5.5v4.294a.5.5 0 0 1-.853.353l-1.467-1.465zm6.911-6.914l1.464 1.464a.5.5 0 0 1-.353.854H8.999a.5.5 0 0 1-.5-.5V2.793a.5.5 0 0 1 .854-.354l1.414 1.415 1.56-1.561a1 1 0 1 1 1.415 1.414l-1.561 1.56z" id="a"/></svg>
`;

const collapseButton = `
  <button id='gitlab-collapse' style='${buttonClearStyles}' class='gitlab-collapse-open'>${compressIcon}</button>
`;


const form = (content) => `
  <div id='gitlab-form-wrapper'>
    ${content}
  </div>
`;

const login = `
  <div>
    <label for='gitlab-token' class='gitlab-label'>Enter your <a class='gitlab-link' href="https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html">personal access token</a></label>
    <input class='gitlab-input' type='password' id='gitlab-token' name='gitlab-token'>
    ${note}
  </div>
  <div class='gitlab-checkbox-wrapper'>
    <input type="checkbox" id="remember_token" name="remember_token" value="remember">
    <label for="remember_token" class='gitlab-checkbox-label'>Remember me</label>
  </div>
  <div class='gitlab-button-wrapper'>
    <button class='gitlab-button-wide' style='${buttonClearStyles}' type='button' id='gitlab-login'> Submit </button>
  </div>
`;

///////////////////////////////////////////////
//////////////// INTERACTIONS /////////////////
///////////////////////////////////////////////

// from https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator
function getBrowserId (sUsrAg) {
  var aKeys = ["MSIE", "Edge", "Firefox", "Safari", "Chrome", "Opera"],
      nIdx = aKeys.length - 1;

  for (nIdx; nIdx > -1 && sUsrAg.indexOf(aKeys[nIdx]) === -1; nIdx--);
  return aKeys[nIdx];
}

function addCommentButtonEvent () {
  // get user agent data
  const { innerWidth,
          innerHeight,
          location: { href },
          navigator: {
            platform, userAgent
          } } = window;
  const browser = getBrowserId(userAgent);

  const scriptName = 'ReviewAppToolbar';
  const projectId = document.querySelector(`script[data-name='${scriptName}']`).getAttribute('data-project');
  const discussionId = document.querySelector(`script[data-name='${scriptName}']`).getAttribute('data-discussion');
  const mrUrl = document.querySelector(`script[data-name='${scriptName}']`).getAttribute('data-mr-url');
  const commentButton = document.getElementById('gitlab-comment-button');

  const details = {
    href,
    platform,
    browser,
    userAgent,
    innerWidth,
    innerHeight,
    projectId,
    discussionId,
    mrUrl,
  };

  commentButton.onclick = postComment.bind(null, details);

}

function addCollapseEvent () {
  const collapseButton = document.getElementById('gitlab-collapse');
  collapseButton.onclick = collapseForm;
}

function addCommentForm () {
  const formWrapper = document.getElementById('gitlab-form-wrapper');
  formWrapper.innerHTML = comment;
  removeButtonAndClickEvent('gitlab-login', authorizeUser);
  addCommentButtonEvent();
  addLogoutButtonEvent();
}

function addLoginButtonEvent () {
  const loginButton = document.getElementById('gitlab-login');
  if (loginButton) { loginButton.onclick = authorizeUser; }
}

function addLogoutButtonEvent () {
  const logoutButton = document.getElementById('gitlab-logout-button');
  if (logoutButton) { logoutButton.onclick = logoutUser; }
}

function addLoginForm () {
  const formWrapper = document.getElementById('gitlab-form-wrapper');
  formWrapper.innerHTML = login;
  removeButtonAndClickEvent('gitlab-comment-button', authorizeUser);
  removeButtonAndClickEvent('gitlab-logout-button', logoutUser);

  addLoginButtonEvent();
}

function authorizeUser () {

  // Clear any old errors
  clearNote('gitlab-token');

  const token = document.getElementById('gitlab-token').value;
  const rememberMe = document.getElementById('remember_token').checked;

  if (!token) {
    postError('Please enter your token.', 'gitlab-token');
    return;
  }

  if (rememberMe) {
    storeToken(token);
  }

  authSuccess(token);
  return;

}

function authSuccess (token) {
  data.token = token;
  addCommentForm();
}


function clearNote (inputId) {
  const note = document.getElementById('gitlab-validation-note');
  note.innerText = '';

  if (inputId) {
    const field = document.getElementById(inputId);
    field.style.borderColor = '#db3b21';
  }
}

function confirmAndClear (discussionId) {
  const commentButton = document.getElementById('gitlab-comment-button');
  const note = document.getElementById('gitlab-validation-note');

  commentButton.innerText = 'Feedback sent';
  note.innerText = `Your comment was successfully posted to issue #${discussionId}`;

  // we can add a fade animation here
  setTimeout(resetCommentButton, 1000);

}

function collapseForm () {
  const container = document.getElementById('gitlab-review-container');
  const collapseButton = document.getElementById('gitlab-collapse');
  const form = document.getElementById('gitlab-form-wrapper');

  container.classList.replace('gitlab-open-wrapper', 'gitlab-closed-wrapper')
  container.style.backgroundColor = 'rgba(255, 255, 255, 0)';
  form.style.display = 'none';

  collapseButton.classList.replace('gitlab-collapse-open', 'gitlab-collapse-closed')
  collapseButton.innerHTML = commentIcon;
  collapseButton.onclick = expandForm;
}

function expandForm () {
  const container = document.getElementById('gitlab-review-container');
  const collapseButton = document.getElementById('gitlab-collapse');
  const form = document.getElementById('gitlab-form-wrapper');

  container.classList.replace('gitlab-closed-wrapper', 'gitlab-open-wrapper')
  container.style.backgroundColor = 'rgba(255, 255, 255, 1)';
  form.style.display = 'flex';

  collapseButton.classList.replace('gitlab-collapse-closed', 'gitlab-collapse-open')
  collapseButton.innerHTML = compressIcon;
  collapseButton.onclick = collapseForm;
}

function getInitialState () {
  const { localStorage } = window;

  if (!localStorage || !localStorage.getItem('token')) {
    return {
      content: login,
      addEvent: addLoginButtonEvent
    };
  }

  data.token = localStorage.getItem('token');

  return {
    content: comment,
    addEvent: () => {
      addCommentButtonEvent();
      addLogoutButtonEvent();
    }
  };
}

function logoutUser () {
  const { localStorage } = window;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  if (!localStorage) {
    return;
  }

  localStorage.clear();
  addLoginForm();
}

function postComment ({
  href,
  platform,
  browser,
  userAgent,
  innerWidth,
  innerHeight,
  projectId,
  discussionId,
  mrUrl,
}) {

  // Clear any old errors
  clearNote();

  setInProgressState();

  const commentText = document.getElementById('gitlab-comment').value;

  const detailText = `
    <details>
      <summary>Metadata</summary>
      Posted from ${href} | ${platform} | ${browser} | ${innerWidth} x ${innerHeight}.
      <br /><br />
      *User agent: ${userAgent}*
    </details>
  `

  const url = `
    ${mrUrl}/api/v4/projects/${projectId}/issues/${discussionId}/discussions?body=
    ${encodeURIComponent(commentText)}${encodeURIComponent(detailText)}
  `;

  fetch(url, {
     method: 'POST',
     headers: {
      'PRIVATE-TOKEN': data.token
    }
  })
  .then((response) => {

    if (response.ok) {
      confirmAndClear(discussionId);
      return;
    }

    throw new Error(`${response.status}: ${response.statusText}`)

  })
  .catch((err) => {
    postError(`The feedback was not sent successfully. Please try again. Error: ${err.message}`, 'gitlab-comment');
    resetCommentBox();
  });

}

function postError (message, inputId) {
  const note = document.getElementById('gitlab-validation-note');
  const field = document.getElementById(inputId);
  field.style.borderColor = '#db3b21';
  note.style.color = '#db3b21';
  note.innerText = message;
}

function removeButtonAndClickEvent (buttonId, eventListener) {
  const button = document.getElementById(buttonId);
  if (button) {
    button.removeEventListener(eventListener);
  }
}

function resetCommentBox() {
  const commentBox = document.getElementById('gitlab-comment');
  const commentButton = document.getElementById('gitlab-comment-button');

  commentButton.innerText = 'Send feedback';
  commentButton.classList.replace('gitlab-button-secondary', 'gitlab-button-success');
  commentButton.style.opacity = 1;

  commentBox.style.pointerEvents = 'auto';
  commentBox.style.color = 'rgba(0, 0, 0, 1)';
}

function resetCommentButton() {
  const commentBox = document.getElementById('gitlab-comment');
  const note = document.getElementById('gitlab-validation-note');

  commentBox.value = '';
  note.innerText = '';
  resetCommentBox();
}

function setInProgressState() {
  const commentButton = document.getElementById('gitlab-comment-button');
  const commentBox = document.getElementById('gitlab-comment');

  commentButton.innerText = 'Sending feedback';
  commentButton.classList.replace('gitlab-button-success', 'gitlab-button-secondary');
  commentButton.style.opacity = 0.5;
  commentBox.style.color = 'rgba(223, 223, 223, 0.5)';
  commentBox.style.pointerEvents = 'none';
}

function storeToken (token) {

  const { localStorage } = window;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  if (!localStorage) {
    return;
  }

  localStorage.setItem('token', token);

}


///////////////////////////////////////////////
///////////////// INJECTION //////////////////
///////////////////////////////////////////////

window.addEventListener('load', () => {
  const { content, addEvent } = getInitialState();

  const container = document.createElement('div');
  container.setAttribute('id', 'gitlab-review-container');
  container.insertAdjacentHTML('beforeend', collapseButton);
  container.insertAdjacentHTML('beforeend', form(content));

  document.body.insertBefore(container, document.body.firstChild);
  addStylesheet();
  addEvent();
  addCollapseEvent();
});
