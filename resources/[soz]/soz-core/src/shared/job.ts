import { ZoneOptions } from '../client/target/target.factory';
import { ClientEvent } from './event';

export enum JobType {
    Unemployed = 'unemployed',
    FBI = 'fbi',
    Adsl = 'adsl',
    Delivery = 'delivery',
    Religious = 'religious',
    Scrapper = 'scrapper',
    LSPD = 'lspd',
    BCSO = 'bcso',
    LSMC = 'lsmc',
    Taxi = 'taxi',
    Food = 'food',
    News = 'news',
    Garbage = 'garbage',
    Oil = 'oil',
    CashTransfer = 'cash-transfer',
    Bennys = 'bennys',
    Upw = 'upw',
    Pawl = 'pawl',
    Baun = 'baun',
    Ffs = 'ffs',
}

export type Job = {
    // Must use the getJobs method to generate the id from the object.
    id: JobType;
    grades: JobGrade[];
    label: string;
    permissions: {
        [key: string]: {
            label: string;
        };
    };
    platePrefix?: string;
    // TODO: Complete when necessary
    temporary?: any;
    bossZones?: any;
    canInvoice?: boolean;
    menuCallback?: ClientEvent;
    resell?: any;
};

export type JobGrade = {
    id: number;
    jobId: string;
    name: string;
    weight: number;
    salary: number;
    owner: number;
    is_default: boolean;
    permissions: string[];
};

export const JobCloakrooms: Partial<Record<JobType, ZoneOptions[]>> = {
    [JobType.Baun]: [
        {
            center: [106.36, -1299.08, 28.77],
            length: 0.4,
            width: 2.3,
            minZ: 27.82,
            maxZ: 30.27,
            heading: 30,
            data: {
                id: 'jobs:baun:cloakroom:unicorn_1',
                event: 'jobs:client:baun:OpenCloakroomMenu', // Tech debt as it's not homogeneous
                job: JobType.Baun,
                storage: 'baun_unicorn_cloakroom_1',
            },
        },
        {
            center: [109.05, -1304.24, 28.77],
            length: 2.25,
            width: 0.4,
            minZ: 27.87,
            maxZ: 30.27,
            heading: 30,
            data: {
                id: 'jobs:baun:cloakroom:unicorn_2',
                event: 'jobs:client:baun:OpenCloakroomMenu', // Tech debt as it's not homogeneous
                job: JobType.Baun,
                storage: 'baun_unicorn_cloakroom_2',
            },
        },
        {
            center: [-1381.38, -602.26, 30.32],
            length: 2.0,
            width: 6.4,
            minZ: 29.92,
            maxZ: 31.92,
            heading: 303,
            data: {
                id: 'jobs:baun:cloakroom:bahama_1',
                event: 'jobs:client:baun:OpenCloakroomMenu', // Tech debt as it's not homogeneous
                job: JobType.Baun,
                storage: 'baun_bahama_cloakroom_1',
            },
        },
    ],
    [JobType.Ffs]: [
        {
            center: [706.41, -959.03, 30.4],
            length: 0.5,
            width: 4.25,
            minZ: 29.4,
            maxZ: 31.6,
            heading: 0,
            data: {
                id: 'jobs:ffs:cloakroom',
                event: 'jobs:client:ffs:OpenCloakroomMenu', // Tech debt as it's not homogeneous
                job: JobType.Ffs,
                storage: 'ffs_cloakroom',
            },
        },
    ],
};
