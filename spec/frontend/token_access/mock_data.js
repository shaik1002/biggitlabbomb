export const enabledJobTokenScope = {
  data: {
    project: {
      id: '1',
      ciCdSettings: {
        jobTokenScopeEnabled: true,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const disabledJobTokenScope = {
  data: {
    project: {
      id: '1',
      ciCdSettings: {
        jobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const projectsWithScope = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        projects: {
          __typename: 'ProjectConnection',
          nodes: [
            {
              id: '2',
              fullPath: 'root/332268-test',
              name: 'root/332268-test',
              namespace: {
                id: '1234',
                fullPath: 'root',
              },
            },
          ],
        },
      },
    },
  },
};

export const addProjectSuccess = {
  data: {
    ciJobTokenScopeAddProject: {
      errors: [],
      __typename: 'CiJobTokenScopeAddProjectPayload',
    },
  },
};

export const removeProjectSuccess = {
  data: {
    ciJobTokenScopeRemoveProject: {
      errors: [],
      __typename: 'CiJobTokenScopeRemoveProjectPayload',
    },
  },
};

export const updateScopeSuccess = {
  data: {
    projectCiCdSettingsUpdate: {
      ciCdSettings: {
        jobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'ProjectCiCdSettingsUpdatePayload',
    },
  },
};

export const mockGroups = [
  {
    id: 1,
    name: 'some-group',
    fullPath: 'some-group',
    __typename: 'Group',
  },
  {
    id: 2,
    name: 'another-group',
    fullPath: 'another-group',
    __typename: 'Group',
  },
  {
    id: 3,
    name: 'a-sub-group',
    fullPath: 'another-group/a-sub-group',
    __typename: 'Group',
  },
];

export const mockProjects = [
  {
    id: 1,
    name: 'merge-train-stuff',
    namespace: {
      id: '1235',
      fullPath: 'root',
    },
    fullPath: 'root/merge-train-stuff',
    isLocked: false,
    __typename: 'Project',
  },
  {
    id: 2,
    name: 'ci-project',
    namespace: {
      id: '1236',
      fullPath: 'root',
    },
    fullPath: 'root/ci-project',
    isLocked: true,
    __typename: 'Project',
  },
];

export const mockFields = [
  {
    key: 'fullPath',
    label: '',
  },
  {
    key: 'actions',
    label: '',
  },
];

export const inboundJobTokenScopeEnabledResponse = {
  data: {
    project: {
      id: '1',
      ciCdSettings: {
        inboundJobTokenScopeEnabled: true,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const inboundJobTokenScopeDisabledResponse = {
  data: {
    project: {
      id: '1',
      ciCdSettings: {
        inboundJobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      __typename: 'Project',
    },
  },
};

export const inboundGroupsAndProjectsWithScopeResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: '1',
      ciJobTokenScope: {
        __typename: 'CiJobTokenScopeType',
        inboundAllowlist: {
          __typename: 'ProjectConnection',
          nodes: [
            {
              __typename: 'Project',
              fullPath: 'root/ci-project',
              id: 'gid://gitlab/Project/23',
              name: 'ci-project',
              namespace: { id: 'gid://gitlab/Namespaces::UserNamespace/1', fullPath: 'root' },
            },
          ],
        },
        groupsAllowlist: {
          __typename: 'GroupConnection',
          nodes: [
            {
              __typename: 'Group',
              fullPath: 'root/ci-group',
              id: 'gid://gitlab/Group/45',
              name: 'ci-group',
            },
          ],
        },
      },
    },
  },
};

export const inboundAddGroupOrProjectSuccessResponse = {
  data: {
    ciJobTokenScopeAddProject: {
      errors: [],
      __typename: 'CiJobTokenScopeAddProjectPayload',
    },
  },
};

export const inboundRemoveGroupSuccess = {
  data: {
    ciJobTokenScopeRemoveProject: {
      errors: [],
      __typename: 'CiJobTokenScopeRemoveGroupPayload',
    },
  },
};

export const inboundRemoveProjectSuccess = {
  data: {
    ciJobTokenScopeRemoveProject: {
      errors: [],
      __typename: 'CiJobTokenScopeRemoveProjectPayload',
    },
  },
};

export const inboundUpdateScopeSuccessResponse = {
  data: {
    projectCiCdSettingsUpdate: {
      ciCdSettings: {
        inboundJobTokenScopeEnabled: false,
        __typename: 'ProjectCiCdSetting',
      },
      errors: [],
      __typename: 'ProjectCiCdSettingsUpdatePayload',
    },
  },
};
